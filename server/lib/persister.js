/**
 * Created by JetBrains PhpStorm.
 * User: fbeauchamp
 * Date: 05/09/13
 * Time: 15:24
 * To change this template use File | Settings | File Templates.
 */


var _ = require('lodash'),
    Promise = require("bluebird"),
    counters,
    client,
    pg = require('pg'); //native libpq bindings = `var pg = require('pg').native`;

var env = process.env.NODE_ENV || 'prod';
if ('prod' == env) {
    console.log('prod');
    config = require('../config.dev.js');
} else {
    console.log('dev');
    config = require('../config.dev.js');
}

client = new pg.Client(config.connString);

resetCounters();
client.connect();//@todo watchdog of connexion


function resetCounters() {
    counters = {
        last_reset: new Date(),
        numbers: {
            query: 0,
            update: 0,
            insert: 0,
            get: 0,
            where: 0,
            remove: 0,
            upsert: 0,
            insdate: 0

        }
    }
}
Date.prototype.setISO8601 = function (string) {
    var regexp = "([0-9]{4})(-([0-9]{2})(-([0-9]{2})" +
        "(T([0-9]{2}):([0-9]{2})(:([0-9]{2})(\.([0-9]+))?)?" +
        "(Z|(([-+])([0-9]{2}):([0-9]{2})))?)?)?)?";
    var d = string.match(new RegExp(regexp));
    var offset = 0;
    var date = new Date(d[1], parseInt(d[3], 10) - 1, parseInt(d[5], 10));
    if (d[7]) {
        date.setHours(parseInt(d[7], 10));
    }
    if (d[8]) {
        date.setMinutes(parseInt(d[8], 10));
    }
    if (d[10]) {
        date.setSeconds(parseInt(d[10], 10));
    }
    if (d[12]) {
        date.setMilliseconds(Number("0." + d[12]) * 1000);
    }
    if (d[14]) {
        offset = (Number(d[16]) * 60) + Number(d[17]);
        offset *= ((d[15] == '-') ? 1 : -1);
    }
    this.setTime(+date);
    offset -= date.getTimezoneOffset();
    var time = (Number(date) + (offset * 60 * 1000));
    this.setTime(Number(time));
};


var table_desc = {}; //cache of table descriptions

function getIndexes(schema, table) {
    return new Promise(function (resolve, reject) {
        var sql = 'select\
        t.relname as table_name, \
        i.relname as index_name,\
            a.attname as column_name,\
            indisprimary as primary,\
            ns.nspname as shcema_name\
        from\
        pg_class t\
        inner join pg_index ix ON t.oid = ix.indrelid\
        inner join  pg_class i ON i.oid = ix.indexrelid\
        inner join pg_attribute a ON a.attrelid = t.oid and a.attnum = ANY(ix.indkey)\
        inner join pg_namespace ns on t.relnamespace = ns.oid\
        where\
        indisunique = true\
        and ns.nspname = $1\
        and t.relname = $2\
        order by\
        t.relname,\
            i.relname'

        client.query(sql, [schema, table], function (err, res) {
            if (err) {
                console.log(err);
                reject(err);
                return;
            }
            var indexes = {};

            _.each(res.rows, function (row) {
                if (!indexes[row.index_name]) {
                    indexes[row.index_name] = {fields: [], primary: row.primary, index_name: row.index_name}
                }
                indexes[row.index_name].fields.push(row.column_name);
            });
            resolve(indexes)
        });

    });
}

function getFieldsDesc(schema_name, table_name) {

    return new Promise(function (resolve, reject) {


        var query = client.query(
            'select column_name,udt_name from INFORMATION_SCHEMA.COLUMNS where table_name = $1 and table_schema= $2 ',
            [table_name, schema_name],
            function (err, desc) {
                if (err) {
                    return reject(err);
                }
                if (desc.rowCount == 0) {
                    var e = new Error('la table *' + table_name + '* n\'existe pas')
                    return reject(e);
                }
                var fields = {};
                var hstore_name = false;
                var geometry_name = false;
                _.each(desc.rows, function (row) {
                    if (row.udt_name == 'hstore') {
                        hstore_name = row.column_name; //le champ hstore n'apparait pas dans la liste des vrais champs
                    } else {
                        if(row.udt_name =='geometry')
                            geometry_name= row.column_name;
                        else
                            fields[row.column_name] = row.udt_name;
                    }
                });
                console.log(fields);
                resolve( {
                    table: table_name,
                    schema: schema_name,
                    fields: fields,
                    hstore_name: hstore_name,
                    geometry_name: geometry_name
                });
            });

    });
}


function getTableDesc(table) {
    return new Promise(function (resolve, reject) {
        var table_name = table, schema_name = 'public', pos;
        if (table_desc[table]) {
            return resolve(table_desc[table]);
        }
        if (!client) {
            return reject(new Error('pas de connexion à la base'));
        }

        if ((pos = table.indexOf('.')) != -1) {
            schema_name = table.substring(0, pos);
            table_name = table.substring(pos + 1);
        }
        var full_desc= {};
        return getFieldsDesc(schema_name, table_name)
            .then(function (desc) {
                full_desc =desc;
                return getIndexes(schema_name, table_name);
            })
            .then(function (indexes) {
                if (!indexes) {
                    throw new Error(' la table ' + schema_name + ' ' + table + ' n\'a pas d\'index');
                }
                if (!_.findWhere(indexes, {primary: true})) {
                    throw new Error(' la table ' + table + ' n\'a pas d\'index primaire');
                }
                full_desc.indexes = indexes;
                table_desc[table_name] = full_desc;
                resolve(table_desc[table_name]);
            }).catch(function (err) {
                reject(err);
            })
    });
}

function chooseUniqueIndex(indexes, fields) {
    var candidates = [];
    _.each(indexes, function (index) {
        if (_.difference(index.fields, fields).length == 0) {
            candidates.push(index.fields);
        }
    });
    return candidates;
}

function filterPhysicalAttributes(table_desc, values) {
    var physical_attributes = [];
    _.each(values, function (value, key) {
        if (table_desc.fields[key] !== undefined)
            physical_attributes.push(key);
    });
    return physical_attributes;
}

function filterHstoreAttributes(table_desc, values) {
    if (!table_desc.hstore_name)
        return {};
    var non_physical_attributes = [];
    _.each(values, function (value, key) {
        if (table_desc.fields[key] === undefined)
            non_physical_attributes.push(key);
    });
    return non_physical_attributes;
}

function singleQuoteEscape(string) {
    return String(string).replace(/'/g, "''");
}

function singleQuoteUnescape(string) {
    return String(string).replace(/[']+/g, "'");
}

function doubleQuoteEscape(string) {
    return String(string).replace(/\\/, "\\\\").replace(/"/g, '\\\"');
}

function doubleQuoteUnescape(string) {
    return String(string).replace(/["]+/g, '"');
}

function format(desc, field, value) {
    if (_.isArray(value)) {
        return _.map(value, function (subvalue) {
            return format(desc, field, subvalue)
        })
    }
    switch (desc.fields[field]) {
        case 'timestamp':
            try {
                var d = 'string' == typeof value ? new Date(value) : value;
                if (d == 'Invalid Date') {
                    d.setISO8601(value);
                }
                return d;
            } catch (exception) {
                console.log(' date transformation failed')
                return null;
            }
        case 'int4':
            value = (value + '').replace(/^\s+|\s+$/g, ''); //trim
            return (isNaN(parseInt(value))) ? 0 : value;
        default :
            return value;
    }
}


function decodePayload(payload) {
    var matrix = payload.split('*|*').map(function (i) {
        return i.split(':|:')
    });
    var map = {};
    for (var i = 0; i < matrix.length; i++) {
        map[matrix[i][0]] = matrix[i][1] === 'null' ? null : matrix[i][1];
    }
    _.map(map, function (item) {
        return item ? item.replace(/''/g, "'") : item;
    });
    return map;

}

var listeners = [];
client.on('notification', function (data) {
    if (!listeners[data.channel]) {
        return;
    }
    var payload = decodePayload(data.payload);
    if (listeners[data.channel]) {
        _.each(listeners[data.channel], function (fn) {
            fn(payload);
        });
    }
});


var Persister = {
    hstoreToJSON: function (row) {
        if (!row || !row.attributes)
            return row;
        for (var j = 0; j < row.attributes.length; j++) {
            if (row.attributes[j][1] === 'null' || row.attributes[j][1] === null) {
                row[row.attributes[j][0]] = null;
            } else {
                row[row.attributes[j][0]] = singleQuoteUnescape(doubleQuoteUnescape(row.attributes[j][1]));
            }

        }
        delete( row.attributes);

        //some attributes contains json as text
        for (var j = 0; j < row.length; j++) {
            try {
                row[row.attributes[j][0]] = JSON.parse(row[row.attributes[j][0]]);
            } catch (exception) {
                //good js is quiet js
            }
        }
        return row;
    },
    insert: function (table, json, fn) {
        counters.numbers.insert++;
        var sql, values = [];
        return getTableDesc(table)
            .then(function (desc) {
                var psas = filterPhysicalAttributes(desc, json);
                var hsas = filterHstoreAttributes(desc, json);
                var fields = [];
                var placeholders = [];
                var dollar_counter = 1;
                var primary_index_fields = _.findWhere(desc.indexes, {primary: true}).fields
                _.each(psas, function (key) {
                    fields.push(key);
                    values.push(format(desc, key, json[key]));
                    placeholders.push('$' + dollar_counter);
                    dollar_counter++;
                });
                if (hsas.length) { //@todo : use prepared statement inside hstore
                    var hsa_fields = [], hsa_values = [];
                    _.each(hsas, function (key) {
                        var escaped = doubleQuoteEscape(format(desc, key, json[key]));
                        escaped = ((escaped.toUpperCase() == 'NULL' || escaped == null) ? 'NULL' : '"' + escaped + '"');
                        hsa_values.push(
                            '"' + doubleQuoteEscape(key) + '"'
                            + '=>'
                            + escaped
                        );
                    });
                    fields.push(desc.hstore_name);
                    placeholders.push('$' + dollar_counter);
                    //values.push('$escaped$'+hsa_values.join(',')+'$escaped$');
                    values.push(singleQuoteEscape(hsa_values.join(',')));
                    dollar_counter++;
                }

                sql = 'INSERT INTO "' + desc.schema + '"."' + doubleQuoteEscape(desc.table) + '"(' + fields.join(',') + ')';
                sql += "VALUES(" + placeholders.join(',') + ") ";
                if (primary_index_fields.length) {
                    sql += " RETURNING  " + primary_index_fields.join(',');
                }

                return Persister.query(sql, values, fn);
            })
            .catch(function (err) {
                fn && fn.apply(null, [err]);
                if (!fn)
                    throw err
            });
    },
    update: function (table, json, fn) {
        counters.numbers.update++;
        var sql, values;
        return getTableDesc(table)
            .then(function (desc) {
                var candidates = chooseUniqueIndex(desc.indexes, _.keys(json));
                if (!candidates.length) {
                    var e = new Error(" pas de clé unique fournie pour l'update dans " + table + ' ' + json.table_name);
                    console.log(json);
                    console.log(desc);
                    console.log('=============================================')
                    fn && fn(e);
                    if (!fn)
                        throw e;
                }
                var index = candidates[0];
                var primary_index_fields = _.findWhere(desc.indexes, {primary: true}).fields
                var psas = filterPhysicalAttributes(desc, json);
                var hsas = filterHstoreAttributes(desc, json);

                var fields_placeholders = [], idx_fieldplaceholder = [];
                values = [];
                var dollar_counter = 1;
                _.each(psas, function (key) {
                    if (_.contains(index, key)) {
                        return;
                    }
                    fields_placeholders.push(key + '= $' + dollar_counter);

                    values.push(format(desc, key, json[key]));
                    dollar_counter++;
                });
                if (hsas.length) { //@todo : use prepared statement inside hstore as well
                    var hsa_values = [];
                    _.each(hsas, function (key) {
                        var escaped = doubleQuoteEscape(format(desc, key, json[key]));
                        escaped = ((escaped.toUpperCase() == 'NULL' || escaped == null) ? 'NULL' : '"' + escaped + '"');

                        hsa_values.push(
                            '"' + doubleQuoteEscape(key) + '"'
                            + '=>'
                            + escaped
                        );
                    });
                    fields_placeholders.push(desc.hstore_name + '=' + desc.hstore_name + ' || $' + dollar_counter);

                    values.push((hsa_values.join(',')));
                    dollar_counter++;
                }
                _.each(index, function (field) {
                    idx_fieldplaceholder.push(field + '= $' + dollar_counter);
                    values.push(format(desc, field, json[field]));
                    dollar_counter++;
                });


                sql = 'UPDATE "' + desc.schema + '"."' + doubleQuoteEscape(desc.table) + '"';
                sql += " SET  " + fields_placeholders.join(',');
                sql += " WHERE  " + idx_fieldplaceholder.join(' AND ');
                if (primary_index_fields.length) {
                    sql += " RETURNING  " + primary_index_fields.join(',');
                }
                return Persister.query(sql, values, fn);

            }).catch(function (err) {
                fn && fn.apply(null, [err]);
                if (!fn)
                    throw err
            })
    },
    insdate: function (table, json, fn) {
        counters.numbers.insdate++;
        return Persister.insert(table, json).then(function (res) {
            fn && fn(null, res);
            return res;
        }).catch(function (err) {
            if (err && (err.code == 23505 /*existing row*/ || err.code == 23502 /*null in non nullable row*/)) {
                //tout n'est pas perdu, tentons l'update
                return Persister.update(table, json, fn);
            } else {
                fn && fn(err);
                if (!fn)
                    throw err;
            }
        });
    },
    upsert: function (table, json) {
        counters.numbers.upsert++;
        return Persister.update(table, json)
            .then(function (res) {
                if (res.rowCount === 0) {
                    //if there are two upsert in parallel, you can create a race condition with a
                    //simple update + insert. Making a final update is the insert fail on duplicate  handle this
                    return Persister.insdate(table, json);
                }
                return res;
            })
    },
    get: function (table, id, fn) {
        counters.numbers.get++;
        return getTableDesc(table)
            .then(function (desc) {
                var sql;
                var fields = [];
                for (var field in desc.fields) {
                    fields.push(field);
                }
                if (desc.hstore_name) {
                    fields.push('hstore_to_matrix(' + desc.hstore_name + ') as ' + desc.hstore_name);
                }

                sql = 'SELECT ' + fields.join(',') + ' FROM  "' + desc.schema + '"."' + doubleQuoteEscape(desc.table) + '" WHERE id=$1';
                return Persister.query(sql, [id], fn);
            }).catch(function (error) {
                if (fn) {
                    fn(error);
                } else {
                    throw error;
                }
            });
    },
    remove: function (table, id, fn) {
        counters.numbers.remove++;
        return getTableDesc(table)
            .then(function (desc) {

                var sql = 'DELETE FROM "' + desc.schema + '"."' + doubleQuoteEscape(desc.table) + '" WHERE id=$1';
                return Persister.query(sql, [id], fn);
            });
    },
    where: function (table, filters) {
        counters.numbers.where++;

        return getTableDesc(table)
            .then(function (desc) {

                var psas = filterPhysicalAttributes(desc, filters);
                var hsas = filterHstoreAttributes(desc, filters);

                var fields_placeholders = [];
                var values = [];
                var dollar_counter = 1;

                _.each(psas, function (key) {
                    if (filters[key] == null) {
                        fields_placeholders.push(key + ' IS NULL');

                    } else {
                        if(_.isString(filters[key]) && filters[key].toLowerCase() == 'not null'){
                            fields_placeholders.push(key + ' IS NOT NULL');
                        }else{

                            if (_.isArray(filters[key])) {
                                fields_placeholders.push(key + '= ANY( $' + dollar_counter + ')');
                            } else {
                                fields_placeholders.push(key + '= $' + dollar_counter);
                            }
                        }
                        values.push(format(desc, key, filters[key]));
                        dollar_counter++;
                    }

                });

                if (hsas.length) { //@todo : use prepared statement inside hstore
                    _.each(hsas, function (key) {
                        if (filters[key] == null) {
                            fields_placeholders.push(
                                '(' + desc.hstore_name + "->'" + doubleQuoteEscape(key) + "') IS NULL");

                        } else {
                            if(_.isString(filters[key]) && filters[key].toLowerCase() == 'not null'){
                                fields_placeholders.push(
                                    '(' + desc.hstore_name + "->'" + doubleQuoteEscape(key) + "') IS NOT NULL");
                            }else {
                                if (_.isArray(filters[key])) {
                                    fields_placeholders.push('(' + desc.hstore_name + "->'" + doubleQuoteEscape(key) + "')= ANY( $" + dollar_counter + ")");
                                } else {
                                    fields_placeholders.push(
                                        '(' + desc.hstore_name + "->'" + doubleQuoteEscape(key) + "')=$" + dollar_counter
                                    );
                                }
                                values.push(format(desc, key, filters[key]));
                                dollar_counter++;
                            }
                        }
                    });
                }

                var fields = [];
                for (var field in desc.fields) {
                    fields.push(field);
                }
                if (desc.hstore_name) {
                    fields.push('hstore_to_matrix(' + desc.hstore_name + ') as ' + desc.hstore_name);
                }
                var sql = "SELECT DISTINCT  " + fields.join(',') + '  FROM  "' + desc.schema + '"."' + doubleQuoteEscape(desc.table) + '"';
                sql += " WHERE " + fields_placeholders.join(' AND ');

                return Persister.query(sql, values).then(function (res) {
                    res.rows.map(Persister.hstoreToJSON);
                    return res;
                })

            });
    },
    query: function (sql, values, fn) {
        counters.numbers.query++;
        return new Promise(function (resolve, reject) {
            client.query(sql, values, function (err, results) {
                if (err) {
                    fn && fn(err);
                    reject(err);
                } else {
                    if (results) {
                        results.rows = results.rows.map(Persister.hstoreToJSON);
                        fn && fn(null, results);
                        resolve(results);
                    } else {
                        fn && fn(null, null);
                        resolve();
                    }
                }
            })
        });
    },
    listen: function (channel, fn) {
        Persister.query('LISTEN "' + channel + '"');
        if (!listeners[channel]) {
            listeners[channel] = [fn];
        } else {
            listeners[channel].push(fn);
        }
    },
    getCounters:function(){
        return _.clone(counters);
    },
    resetCounters: resetCounters
};

module.exports = Persister;

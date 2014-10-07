var
    Promise = require("bluebird"),
    ActiveDirectory = require('activedirectory');

//which env ?
var env = process.env.NODE_ENV || 'prod';
if ('prod' == env) {
    console.log('prod');
    config = require('../config.dev.js');
} else {
    console.log('dev');
    config = require('../config.dev.js');
}

//connect to our active directory
var ad = new ActiveDirectory(config.authenticator.activeDirectory);


module.exports = {
    authenticate: function (login, password) {
        return new Promise(function (resolve, reject) {
            ad.authenticate(
                login + '@SDIS71AD.LOCAL',
                password,
                function (err, auth) {
                    if (err) {
                        return reject(err);
                    } else {
                        resolve(auth)
                    }
                });
        });
    },
    findUsers: function(filter){
        return new Promise(function (resolve, reject) {
            ad.findUsers(
                {
                    filter:filter,
                    attributes: [
                        //  'jpegphoto',
                        'userPrincipalName',
                        'sAMAccountName',
                        'mail',
                        'lockoutTime',
                        'whenCreated',
                        'pwdLastSet',
                        'userAccountControl',
                        'employeeID',
                        'sn',
                        'givenName',
                        'initials',
                        'cn',
                        'displayName',
                        'comment',
                        'description'
                    ]
                }, false,
                function (err, users) {
                    if (err) {
                        reject(err);
                    } else {
                        if (users) {
                            resolve(users)
                        } else {
                            resolve(null)
                        }
                    }
                });
        });
    },
    find: function (login) {
        return new Promise(function (resolve, reject) {
            ad.findUser(
                {
                    attributes: [
                        'jpegphoto',
                        'userPrincipalName',
                        'sAMAccountName',
                        'mail',
                        'lockoutTime',
                        'whenCreated',
                        'pwdLastSet',
                        'userAccountControl',
                        'employeeID',
                        'sn',
                        'givenName',
                        'initials',
                        'cn',
                        'displayName',
                        'comment',
                        'description'
                    ]
                }, login + '@SDIS71AD.LOCAL',
                function (err, ad_user) {
                    if (err) {
                        reject(err);
                    } else {
                        if (ad_user) {
                            resolve({
                                login: ad_user.sAMAccountName,
                                type: 'interne',
                                matricule: ad_user.employeeID,
                                mail: ad_user.mail
                            })
                        } else {
                            resolve(null)
                        }
                    }
                });
        });
    }
}
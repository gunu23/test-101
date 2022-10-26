/**
 * Licensed Materials - Property of IBM
 * IBM WebSphere DataPower Appliances
 * Copyright IBM Corporation 2015,2015. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or disclosure
 * restricted by GSA ADP Schedule Contract with IBM Corp.
 */

var mgmt = require('mgmt');
var jose = require('jose');

//disable error object logging
script.defaults({'errorObjectLogging':false});

// Internal Error message to SOAP:Fault
var internalErrorMsg = "Internal Error";

//get action config first
var actionCfg = mgmt.getConfigAsJSON(mgmt.ObjectID.StylePolicyAction,
        session.namedAction);

// We should log all messages into crypto catagory
var logCrypto = console.options({'category': 'crypto'});

if ( !actionCfg ) {
    var error = new Error('Internal error, cannot get action settings');
    logCrypto.error(error);
    session.reject(internalErrorMsg);
    return;
}

// The script is only workable under jose-decrypt action
if ( actionCfg.StylePolicyAction.Type !== 'jose-decrypt' ) {
    var error = new Error(Error.ID.GSCRYPTO_ACTION_TYPE_NOT_MATCH, "jose-decrypt.js", "jose-decrypt");
    logCrypto.error(error);
    session.reject(internalErrorMsg);
    return;
}

//normalize some properties first
normalizeConfig(actionCfg);

//main flow
//try json first and fall back to buffers
session.input.readAsJSON( function (error, json) {
    if ( error ) {
        //fall back to buffers
        session.input.readAsBuffer( function ( error, buffers) {
            if ( error ) {
                logCrypto.error(error);
                session.reject(internalErrorMsg);
                return;
            }
            parseAndDecrypt(buffers);
        } );
        return;
    }
    parseAndDecrypt(json);
} );

function parseAndDecrypt( obj ) {
    try {
        var jweObj = jose.parse( obj );
        var config = actionCfg.StylePolicyAction;

        //dir
        if ( config.JWEDirectKeyObject ) {
            if ( jweObj._type === 'compact' ) {
                // compact
                jweObj.setKey(config.JWEDirectKeyObject.CryptoSSKey.name);
            } else {
                if ( jweObj._jose_header_shared.alg === 'dir' ) {
                    jweObj.setDirectKey(config.JWEDirectKeyObject.CryptoSSKey.name);
                } else {
                    var keyname = config.JWEDirectKeyObject.CryptoSSKey.name;
                    jweObj.getRecipients().forEach(function (recipient) {
                        recipient.setKey(keyname);
                    });
                }
            }
        } else {
            matching(jweObj, config);
        }
        
        var jweDecrypter = jose.createJWEDecrypter( jweObj );
        jweDecrypter.decrypt( function ( error, decryptObj ) {
            if ( error ) {
                logCrypto.error(error);
                session.reject(internalErrorMsg);
                return;
            }
            session.output.write(decryptObj);
        });
    } catch (e) {
        logCrypto.error(e);
        session.reject(internalErrorMsg);
        return;
    }
}

/**
 * get key object name from JOSERecipientIdentifier
 * could be sskey or certificate
 * @param association
 * @returns
 */
function getKeyConfigObjectName( association ) {
    if ( association.Key ) {
        return association.Key.CryptoKey.name;
    } else if ( association.SSKey ) {
        return association.SSKey.CryptoSSKey.name;
    }
    return undefined;
}

/**
 * get key object name from CryptoCertificate or CryptoSSKey
 * @param config object
 * @returns
 */
function getMatchAllKeyConfigObjectName( matchall ) {
    if ( matchall.CryptoKey ) {
        return matchall.CryptoKey.name;
    } else if ( matchall.CryptoSSKey ) {
        return matchall.CryptoSSKey.name;
    }
    return undefined;
}

function matching ( jweobj, config ) {
        if ( jweobj._type === 'compact' ) {
        //compact
        if ( config.SingleSSKey || config.SingleKey ) {
            var keyobj = config.SingleSSKey || config.SingleKey;
            jweobj.setKey(
                    getMatchAllKeyConfigObjectName(keyobj) );
            return;
        }
        var associations = config.RecipientIdentifier;

        for ( var index = 0, len = associations.length; index < len; index++ ) {
            var association = associations[index]; 
            if ( matchingHeader( jweobj.getProtected(), association.JOSERecipientIdentifier.HeaderParam ) ) {
                jweobj.setKey( getKeyConfigObjectName( association.JOSERecipientIdentifier ) );
                return;
            }
        }
        logCrypto.error(Error.ID.GSCRYPTO_JOSE_DECRYPT_NO_ASSOCIATION);
        throw new Error(Error.ID.GSCRYPTO_JOSE_DECRYPT_NO_ASSOCIATION);
    } else {
        //json
        if ( config.SingleSSKey || config.SingleKey ) {
            var keyobj = config.SingleSSKey || config.SingleKey;
            var keyname = getMatchAllKeyConfigObjectName(keyobj);
            //go through all recipients and set the key
            jweobj.getRecipients().forEach(function (recipient) {
                recipient.setKey(keyname)
            });
        } else {
            var associations = config.RecipientIdentifier;
            var recipients = jweobj.getRecipients();
            var matched = false;
            for ( var index = 0, len = recipients.length; index < len; index++ ) {
                var recipient = recipients[index];
                var joseHeaders = mergeHeaders(
                        jweobj._jose_header_shared, recipient.get());
                if ( matchRecipientWithAssociation(recipient, joseHeaders, associations) ) {
                    matched = true;
                }
            }
            if ( !matched ) {
                logCrypto.error(Error.ID.GSCRYPTO_JOSE_DECRYPT_NO_ASSOCIATION);
                throw new Error(Error.ID.GSCRYPTO_JOSE_DECRYPT_NO_ASSOCIATION);
            }
        }
    }
}

function mergeHeaders( header1, header2 ) {
    var rev = {};
    for( var h1 in header1 ) {
        rev[h1] = header1[h1];
    }
    for ( var h2 in header2 ) {
        rev[h2] = header2[h2];
    }
    return rev;
}

function matchRecipientWithAssociation(recipient, headers, associations ) {
    for( var index = 0, len = associations.length; index < len; index++ ) {
        var association = associations[index];
        if ( matchingHeader( headers, association.JOSERecipientIdentifier.HeaderParam ) ) {
            recipient.setKey( getKeyConfigObjectName( association.JOSERecipientIdentifier ) );
            return true;
        } 
    }
    return false;
}

function matchingHeader( headers, associationHeaders ) {
    if ( associationHeaders instanceof Array ) {
        for( var matchIndex = 0, len = associationHeaders.length;
                    matchIndex < len; matchIndex++ ) {
            var match = associationHeaders[matchIndex];

            // special handling for crit because its value is comma separated list.
            if (match['HeaderName'] === 'crit') {
                if (!matchCritHeader(headers, match))
                    return false;
            } else {
                if ( headers[match['HeaderName']] !== match['HeaderValue']) {
                    return false;
                }
            }
        }
    } else {
        // special handling for crit because its value is comma separated list.
        if (associationHeaders['HeaderName'] === 'crit') {
            if (!matchCritHeader(headers, associationHeaders))
                return false;
        } else {
            if ( headers[associationHeaders['HeaderName']] !== associationHeaders['HeaderValue'] )
                return false;
        }
    }
     return true;
}

function normalizeConfig( config ) {
    var assoPairs = config.StylePolicyAction.RecipientIdentifier;
    if ( assoPairs && !( assoPairs instanceof Array) ) {
        config.StylePolicyAction.RecipientIdentifier = [assoPairs];
    }
}

/**
 * specially handle crit Header Parameter, array order is not important
 */
function matchCritHeader (joseHeader, match) {
    if (joseHeader['crit']) {
        var arr = match['HeaderValue'].split(",");
        for (var i = 0; i < arr.length; i++) {
            arr[i] = arr[i].trim();
            if (joseHeader['crit'].indexOf(arr[i]) == -1) {
                return false;
            }
        }
        for (var i = 0; i < joseHeader['crit'].length; i++) {
            if (arr.indexOf(joseHeader['crit'][i]) == -1) {
                return false;
            }
        }
    } else {
        return false;
    }
    return true;
}

/**
 * Licensed Materials - Property of IBM
 * IBM WebSphere DataPower Appliances
 * Copyright IBM Corporation 2015,2016. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or disclosure
 * restricted by GSA ADP Schedule Contract with IBM Corp.
 */

var mgmt = require('mgmt');
var jose = require('jose');

//disable error object logging
script.defaults({'errorObjectLogging':false});

// Internal Error message to SOAP:Fault
var internalErrorMsg = "Internal Error";

//get action config
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

// The script is only workable under jose-verify action
if ( actionCfg.StylePolicyAction.Type !== 'jose-verify' ) {
    var error = new Error(Error.ID.GSCRYPTO_ACTION_TYPE_NOT_MATCH, "jose-verify.js", "jose-verify");
    logCrypto.error(error);
    session.reject(internalErrorMsg);
    return;
}
//normalize some properties first
normalizeConfig(actionCfg);
// special handling if all signatures and associations match but no verification
// is going to be verified, we pass the verification process.
var goVerify = false;

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
            parseAndVerify(buffers);
        } );
        return;
    }
    parseAndVerify(json);
} );


function parseAndVerify( obj ) {
    try {
        var jwsObj = jose.parse( obj );

        //TODO: need to check the returned object

        var jwsheaders = jwsObj.getSignatures();
        if ( jwsheaders.length == 0 ) {
            logCrypto.error(Error.ID.GSCRYPTO_JOSE_VERIFY_NO_SIGNATURE_IN_PAYLOAD);
            throw new Error(Error.ID.GSCRYPTO_JOSE_VERIFY_NO_SIGNATURE_IN_PAYLOAD);
        }
        jwsheaders.forEach ( function ( jwsheader ) {
            matching(jwsheader, actionCfg);
        });

        //check if all signatures match a jose association
        verifySignatures(jwsheaders);
        //check if all jose association are used
        verifyAssociations(actionCfg);

        // if no signature is going to be verified, pass the validate call.
        if (!goVerify) {
            if (actionCfg.StylePolicyAction.JWSVerifyStripSignature === 'on') {
                verifyCallback(jwsObj.getPayload());
            } else {
                // follow DataPower verify action behavior, it will write original
                // signed input to output context.
                verifyCallback(obj);
            }

            return;
        }
        var jwsvalidater = jose.createJWSVerifier( jwsObj );
        var output;
        if (actionCfg.StylePolicyAction.JWSVerifyStripSignature === 'on') {
            output = jwsObj.getPayload();
        } else {
            // follow DataPower verify action behavior, it will write original
            // signed input to output context.
            output = obj;
        }
        jwsvalidater.validate( 
                verifyCallback.bind( null, output) );
    } catch (e) {
        logCrypto.error(e);
        session.reject(internalErrorMsg);
        return;
    }
}

/**
 * callback function of JWSValidater
 * @param obj      original payload or jws object based on strip-signature value 
 * @param error
 * @returns
 */
function verifyCallback( obj, error ) {
    if ( error ) {
        logCrypto.error(error);
        session.reject(internalErrorMsg);
        return;
    }
    session.output.write(obj);
}

/**
 * verify if all signatures match a JOSEAssociation
 * @param jwsheaders
 * @returns
 */
function verifySignatures( jwsheaders ) {
    jwsheaders.forEach( function ( jwsheader ) {
        if ( !jwsheader.matchedAssociation ) {
            logCrypto.error(Error.ID.GSCRYPTO_JOSE_VERIFY_SIGNATURE_NOT_MATCHED);
            throw new Error(Error.ID.GSCRYPTO_JOSE_VERIFY_SIGNATURE_NOT_MATCHED);
        }
    });
}

/**
 * verify if all JOSEAssociation are used at least once
 * @param config
 * @returns
 */
function verifyAssociations( config ) {
    if ( config.StylePolicyAction.SingleCertificate || config.StylePolicyAction.SingleSSKey ) {
        return;
    } else {
        var associations = config.StylePolicyAction.SignatureIdentifier;
        associations.forEach( function ( association ) {
            if (!association.matchedSignature) {
                logCrypto.error(Error.ID.GSCRYPTO_JOSE_VERIFY_ASSOCIATION_NOT_USED);
                throw new Error(Error.ID.GSCRYPTO_JOSE_VERIFY_ASSOCIATION_NOT_USED);
            }
        });
    }
}

/**
 * try to match the signature with config object's association criteria
 * if there is matched association, set the key to signature if verify is on
 * and also add a flag to signature and association. 
 * @param signature JWSSignedHeader
 * @param config
 */
function matching( jwsheader, config ) {
    if ( config.StylePolicyAction.SingleCertificate || config.StylePolicyAction.SingleSSKey ) {
        //match all
        var keyObj = config.StylePolicyAction.SingleCertificate || config.StylePolicyAction.SingleSSKey;
        var key = getMatchAllKeyConfigObjectName( keyObj );
        if ( key ) {
            jwsheader.setKey( key );
            goVerify = true;
        }
        jwsheader.matchedAssociation = true;
    } else {
        var associations = config.StylePolicyAction.SignatureIdentifier;
        associations.forEach( function ( association ) {
            if (!jwsheader.cacheJOSEHeader) {
                jwsheader.cacheJOSEHeader = jwsheader.getJOSEHeader();
            }
            if ( associationMatching(jwsheader.cacheJOSEHeader, 
                    association.JOSESignatureIdentifier.HeaderParam) ) {
                // already matched with previous association, log warning
                // message, won't setKey again!
                if (jwsheader.matchedAssociation) {
                    logCrypto.warn(Error.ID.GSCRYPTO_JOSE_VERIFY_ASSOCIATION_DUPLICATED, association.JOSESignatureIdentifier.name);
                } else {
                    if ( association.JOSESignatureIdentifier.ValidAlgorithms ) {
                        //stop now if the alg is not in the validAlgs list
                        jwsheader.validAlgs(association.JOSESignatureIdentifier.ValidAlgorithms);
                    }
                    if ( association.JOSESignatureIdentifier.Verify === 'on' ) {
                        var assokey = getKeyConfigObjectName( 
                                association.JOSESignatureIdentifier );
                        if (assokey) {
                            jwsheader.setKey( assokey );
                            goVerify = true;
                        }
                    }
                }
                jwsheader.matchedAssociation = true;
                association.matchedSignature = true;
            }
        });
    }
}

/**
 * get key object name from JOSESignatureIdentifier
 * could be sskey or certificate
 * @param association
 * @returns
 */
function getKeyConfigObjectName( association ) {
    if ( association.Certificate ) {
        return association.Certificate.CryptoCertificate.name;
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
    if ( matchall.CryptoCertificate ) {
        return matchall.CryptoCertificate.name;
    } else if ( matchall.CryptoSSKey ) {
        return matchall.CryptoSSKey.name;
    }
    return undefined;
}

/**
 * match the jose header and matching criteria
 * @param joseHeader
 * @param associationMatch
 * @returns {Boolean}
 */
function associationMatching( joseHeader, associationMatch ) {
    if ( associationMatch instanceof Array ) {
        for( var matchIndex = 0, len = associationMatch.length;
                matchIndex < len; matchIndex++ ) {
            var match = associationMatch[matchIndex];

            // special handling for crit because its value is comma separated list.
            if (match['HeaderName'] === 'crit') {
                if (!matchCritHeader(joseHeader, match))
                    return false;
            } else {
                if ( joseHeader[match['HeaderName']] !== match['HeaderValue']) {
                    return false;
                }
            }
        }
    } else {
        // special handling for crit because its value is comma separated list.
        if (associationMatch['HeaderName'] === 'crit') {
            if (!matchCritHeader(joseHeader, associationMatch))
                return false;
        } else {
            if ( joseHeader[associationMatch['HeaderName']] !== associationMatch['HeaderValue'] ) {
                return false;
            }
        }
    }
    return true;
}

function normalizeConfig( config ) {
    var assos = config.StylePolicyAction.SignatureIdentifier;
    if ( assos && !( assos instanceof Array) ) {
        config.StylePolicyAction.SignatureIdentifier = [assos];
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

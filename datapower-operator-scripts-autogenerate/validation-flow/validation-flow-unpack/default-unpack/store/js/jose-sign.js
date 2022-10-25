/**
 * Licensed Materials - Property of IBM
 * IBM WebSphere DataPower Appliances
 * Copyright IBM Corporation 2015,2015. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or disclosure
 * restricted by GSA ADP Schedule Contract with IBM Corp.
 */

var mgmt = require('mgmt');
var jose = require('jose');
var util = require('util');

// Internal Error message to SOAP:Fault
var internalErrorMsg = "Internal Error";

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

// The script is only workable under jose-sign action
if ( actionCfg.StylePolicyAction.Type !== 'jose-sign' ) {
    var error = new Error(Error.ID.GSCRYPTO_ACTION_TYPE_NOT_MATCH, "jose-sign.js", "jose-sign");
    logCrypto.error(error);
    session.reject(internalErrorMsg);
    return;
}

// main flow
session.input.readAsBuffers(function(error, buffers) {
    if (error) {
        logCrypto.error(error);
        session.reject(internalErrorMsg);
    } else {
        try {
            performJOSESign(buffers);
        } catch (e) {
            logCrypto.error(e);
            session.reject(internalErrorMsg);
        }
    }
});

/**
 * get key object name from JSON config object
 * could be sskey or key
 * @param signatures vector
 * @return key name
 */
function getKeyConfigObjectName( sig ) {
    if ( sig.Key ) {
        return sig.Key.CryptoKey.name;
    } else if ( sig.SSKey ) {
        return sig.SSKey.CryptoSSKey.name;
    }
    return undefined;
}

function performJOSESign(buffers) {
    var config = actionCfg.StylePolicyAction;
    var ser = config.JOSESerializationType.toLowerCase();
    // current release, only one element -> object
    // future release, multiple elements -> array
    var sig_vector = config.JWSSignatureObject.JWSSignature;

    if (ser === 'compact') {
        // for compact, sig_vector should be object
        var alg = sig_vector.Algorithm;
        var key = getKeyConfigObjectName(sig_vector);
        var protected_header = sig_vector.ProtectedHeader; // object or array

        // for compact, we only care about protected header.
        var jwsHdr = jose.createJWSHeader(key, alg);
        if (protected_header) {
            if ( protected_header instanceof Array ) {
                protected_header.forEach( function (pHeader) {
                    normalizeCritHeader(pHeader);
                    jwsHdr.setProtected(pHeader['HeaderName'], pHeader['HeaderValue']);
                } );
            } else {
                normalizeCritHeader(protected_header);
                jwsHdr.setProtected(protected_header['HeaderName'], protected_header['HeaderValue']);
            }
        }

        jose.createJWSSigner(jwsHdr).update(buffers).sign(ser, function(error, jwsObj) {
            if (error) {
                logCrypto.error(error);
                session.reject(internalErrorMsg);
            } else {
                session.output.write(jwsObj);
            }
        });
    } else { /* JSON serialization */
        // for json, sig_vector could be object or array (for current
        // release, we support one element)
        if (util.safeTypeOf(sig_vector) === 'object') {
            // object
            var alg = sig_vector.Algorithm;
            var key = getKeyConfigObjectName(sig_vector);
            var protected_header = sig_vector.ProtectedHeader; // object or array
            var unprotected_header = sig_vector.UnprotectedHeader; // object or array

            // for json, need to add unprotected header.
            var jwsHdr = jose.createJWSHeader(key, alg);
            if (protected_header) {
                if ( protected_header instanceof Array ) {
                    protected_header.forEach( function (pHeader) {
                        normalizeCritHeader(pHeader);
                        jwsHdr.setProtected(pHeader['HeaderName'], pHeader['HeaderValue']);
                    });
                } else {
                    normalizeCritHeader(protected_header);
                    jwsHdr.setProtected(protected_header['HeaderName'], protected_header['HeaderValue']);
                }
            }

            if (unprotected_header) {
                if ( unprotected_header instanceof Array ) {
                    unprotected_header.forEach( function (upHeader) {
                        normalizeCritHeader(upHeader);
                        jwsHdr.setUnprotected(upHeader['HeaderName'], upHeader['HeaderValue']);
                    });
                } else {
                    normalizeCritHeader(unprotected_header);
                    jwsHdr.setUnprotected(unprotected_header['HeaderName'], unprotected_header['HeaderValue']);
                }
            }


            jose.createJWSSigner(jwsHdr).update(buffers).sign(ser, function(error, jwsObj) {
                if (error) {
                    logCrypto.error(error);
                    session.reject(internalErrorMsg);
                } else {
                    session.output.write(jwsObj);
                }
            });
        } else {
            // TODO: array
            var error = new Error("Internal error, not support in release 7.2!");
            logCrypto.error(error);
            session.reject(internalErrorMsg);
            return;
        }
    }
}

/**
 * Normalize 'crit' value
 * 'crit' value uses comma separated list and compose it to array. We don't
 *  accept name containing comma
 *  Remove whitespace from both sides of a string.
 */
function normalizeCritHeader ( header ) {
    if (header['HeaderName'] === 'crit') {
        header['HeaderValue'] = header['HeaderValue'].split(",");
        for (var i = 0; i < header['HeaderValue'].length; i++) {
            header['HeaderValue'][i] = header['HeaderValue'][i].trim();
        }
    }
}

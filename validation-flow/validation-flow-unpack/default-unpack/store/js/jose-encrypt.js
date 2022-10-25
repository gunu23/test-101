/**
 * Licensed Materials - Property of IBM
 * IBM WebSphere DataPower Appliances
 * Copyright IBM Corporation 2015,2016. All Rights Reserved.
 * US Government Users Restricted Rights - Use, duplication or disclosure
 * restricted by GSA ADP Schedule Contract with IBM Corp.
 */

var mgmt = require('mgmt');
var jose = require('jose');

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

// The script is only workable under jose-encrypt action
if ( actionCfg.StylePolicyAction.Type !== 'jose-encrypt' ) {
    var error = new Error(Error.ID.GSCRYPTO_ACTION_TYPE_NOT_MATCH, "jose-encrypt.js", "jose-encrypt");
    logCrypto.error(error);
    session.reject(internalErrorMsg);
    return;
}

//main flow
session.input.readAsBuffers( function (error, buffers) {
  if ( error ) {
      logCrypto.error(error);
      session.reject(internalErrorMsg);
      return;
  }
  try {
      jweEncrypt(buffers);
  } catch (e) {
      logCrypto.error(e);
      session.reject(internalErrorMsg);
  }

});


/**
 * get key object name from JOSEAssociation
 * could be sskey or certificate
 * @param association
 * @returns
 */
function getKeyConfigObjectName( recipient ) {
    if ( recipient.Certificate ) {
        return recipient.Certificate.CryptoCertificate.name;
    } else if ( recipient.SSKey ) {
        return recipient.SSKey.CryptoSSKey.name;
    }
    return undefined;
}

/**
 * create jwe header, set header values and then
 * create jwe encrypter and perform encrypt
 * write the jwe output to session.output
 * @param buffers
 */
function jweEncrypt( buffers ) {
    var config = actionCfg.StylePolicyAction;
    var jweHeader = jose.createJWEHeader(config.JWEEncAlgorithm);
    var jweType = config.JOSESerializationType.toLowerCase();
    var headerCfg = config.JWEHeaderObject.JWEHeader;
    

    if ( headerCfg.JWEProtectedHeader ) {
        if ( headerCfg.JWEProtectedHeader instanceof Array ) {
            headerCfg.JWEProtectedHeader.forEach( function (pHeader) {
                normalizeCritHeader(pHeader);
                jweHeader.setProtected( pHeader['HeaderName'], pHeader['HeaderValue']);
            });
        } else {
            normalizeCritHeader(headerCfg.JWEProtectedHeader);
            jweHeader.setProtected ( headerCfg.JWEProtectedHeader['HeaderName'], 
                    headerCfg.JWEProtectedHeader['HeaderValue']);
        }
    }

    var recipient = headerCfg.Recipient.JWERecipient;
    var alg = recipient.Algorithm;

    if ( jweType === 'json' || jweType === 'json_flat' ) {

        if ( headerCfg.JWESharedUnprotectedHeader ) {
            if ( headerCfg.JWESharedUnprotectedHeader instanceof Array ) {
                headerCfg.JWESharedUnprotectedHeader.forEach( function ( supHeader ) {
                    normalizeCritHeader(supHeader);
                    jweHeader.setUnprotected(supHeader['HeaderName'], supHeader['HeaderValue']);
                });
            } else {
                normalizeCritHeader(headerCfg.JWESharedUnprotectedHeader);
                jweHeader.setUnprotected( headerCfg.JWESharedUnprotectedHeader['HeaderName'],
                        headerCfg.JWESharedUnprotectedHeader['HeaderValue']);
            }
        }

        var recipientHeader = getHeaderFromCfg(recipient.UnprotectedHeader);
        if ( alg === 'dir' ) {
            jweHeader.setProtected('alg', alg);
            jweHeader.setKey( recipient.SSKey.CryptoSSKey.name );
            if ( recipientHeader ) {
                jweHeader.addRecipient( recipientHeader );
            }
        } else {
            jweHeader.setProtected('alg', alg);
            if ( recipientHeader ) {
                jweHeader.addRecipient( 
                        getKeyConfigObjectName(recipient), 
                        recipientHeader );
            } else {
                jweHeader.addRecipient(
                        getKeyConfigObjectName(recipient) );
            }
        }
    } else {
        jweHeader.setProtected('alg', alg);
        jweHeader.setKey( getKeyConfigObjectName(recipient) );        
    }
    
    var jweEncrypter = jose.createJWEEncrypter( jweHeader );
    jweEncrypter.update(buffers);
    jweEncrypter.encrypt(jweType, function (error, jweObj) {
        if( error ) {
            logCrypto.error(error);
            session.reject(internalErrorMsg);
            return;
        }
        session.output.write(jweObj);
    });
}

/**
 * retrieve name:value from Match config object
 * @param headers
 */
function getHeaderFromCfg( headers ) {
    var rev = undefined;
    if ( !headers ) {
        return rev;
    }

    rev = {};
    if ( headers instanceof Array ) {
        headers.forEach( function ( header ) {
            normalizeCritHeader(header);
            rev[header['HeaderName']] = header['HeaderValue'];
        });
    } else {
        normalizeCritHeader(headers);
        rev[headers['HeaderName']] = headers['HeaderValue'];
    }
    return rev;
}

/**
 * Normalize 'crit' value
 * 'crit' value uses comma separated list and compose it to array. We don't
 *  accept name containing comma.
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

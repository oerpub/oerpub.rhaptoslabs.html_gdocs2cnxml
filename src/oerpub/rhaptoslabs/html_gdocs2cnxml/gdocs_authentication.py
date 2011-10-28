'''
Get a authorized Google Docs client with OAuth
'''

import gdata.gauth
import gdata.docs.client

def getAuthorizedGoogleDocsClient():
    CONSUMER_KEY = 'anonymous'
    CONSUMER_SECRET = 'anonymous'
    # Change these to your oauth_token/oauth_token_secret!
    # Used account for GSoC 2011: therealmarvapi@googlemail.com
    # ==================================================================================
    # How to generate your own token key and secret:
    # https://groups.google.com/d/msg/google-documents-list-api/kO88KLJWDdQ/I8Xe5khCPp0J
    # ==================================================================================
    TOKEN_KEY = '1/ECMAMpOOdHpT2KaYFZt3mSiHPms-M7nS986FC8hSSxE'
    TOKEN_SECRET = 'Bo4sNz89dWroybxZMoNfCDKs'

    # Client is a Google Docs document client
    gdClient = gdata.docs.client.DocsClient()
    # SSL is required (2011-09-07)
    # http://googleappsdeveloper.blogspot.com/2011/09/requiring-ssl-for-documents-list.html
    gdClient.ssl = True
    gdClient.auth_token = gdata.gauth.OAuthHmacToken(
        CONSUMER_KEY,
        CONSUMER_SECRET,
        TOKEN_KEY,
        TOKEN_SECRET,
        gdata.gauth.ACCESS_TOKEN,
        next=None,
        verifier=None)

    return gdClient

# github_cli_token_gen
Generates github access tokens for the git cli, should be used in conjunction with github_token_revoker to enforce periodic access token refreshes.

## Description

Github offers both MFA and SSO options which enable robust security for github web access, but github make don't offer a similar security level on the command line. Rather github allow users to create long lived access tokens which, if stolen, could be resused of long periods of time without detection. The tokens cannot be set to expire. Morevoer, 

One possible solution is to enforce a revocation policy (daily, weekly, every 48 hours, whatever) in which all access tokens in an org are revoked. This would require a deverloper to update her access token. However, the process for creating an access token through the Github UI has just enough friction to be frustrating for a developer who simple wants to make code commits. This project attempts to solve that problem my creating a command line script which uses OAith 2.0 device grant flow or authorization code flow to validate the user using MFA or SSO and then aut generate a new access token and add it to the keychain.

## Usage

> bundle exec bin/gctg.rb --username <username> --org <org>

## Getting the code

> git clone https://....



# git_pat_revoker
Revokes all PATs in a given SAML SSO org. This should be used in conjuction with policues to enforce periodic access token refreshes. Assumes you have a Github Enterprise account.

## Description
Github offers both SSO for web access options which enable robust security, but github do not offer a similar security level on the command line. Rather github allow users to create long lived personal access tokens (PATs) which, if stolen, could be resused for long periods of time without detection. The tokens cannot be set to expire. IP Whitelisting is the only viable solution to this problem. But leveraging a VPN for everyday coding tasks seems excessive and not applicable for all enterprises.

One possible solution is to enforce a revocation policy (daily, weekly, every 48 hours, whatever) in which all PATs in a SAML SSO org are revoked. This would require a developer to update her access token periodically. This project attempts to solve a portion of this problem via a command line script which deletes all PATs in an SAML SSO org or just PATs for certain memebrs of the org.

## Usage
### To list tokens, run this command:
`> bundle exec bin/revoker.rb -l ORGNAME`
### To revoke tokens, run this command:
`> bundle exec bin/revoker.rb -r ORGNAME`
### To revoke a specific user's token, run this command:
`> bundle exec bin/revoker.rb -r ORGNAME -n SOMENAME`

```
Usage: bundle exec bin/revoker.rb [options]
   -v, --verbose                    Show extra information
   -h, --help                       Show this message
   -r, --revoke ORG                 Revokes all SAML SSO tokens for users in a given org
   -n, --name NAME                  Revokes SAML SSO token for named user in a given org
   -l, --list ORG                   List all SAML SSO tokens for users in a given org
```
The app assumes an environment variable GITHUB_ACCESS_TOKEN will be set with a valid token where the token's scope is _admin:org_.
This could be a personal access token as well. Although it should be for a bot account (and hence not in the SAML SSO org, otherswise you'll revoke your own token).

## Getting the code
`> git clone https://github.com/ngngsoftorg/git_pat_revoker.git`

## Installing the code
```
> rbenv shell 3.0.0
> bundle install
```



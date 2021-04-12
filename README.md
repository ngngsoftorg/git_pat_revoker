# git_pat_revoker
Revokes all PATs in a given SAML SSO org. This should be used iin conjuction with policues to enforce periodic access token refreshes.

## Description
Github offers both MFA and SSO for web access options which enable robust security, but github do not offer a similar security level on the command line. Rather github allow users to create long lived personal access tokens (PATs) which, if stolen, could be resused for long periods of time without detection. The tokens cannot be set to expire. IP Whitelisting is the only viable solution to this problem. But leveraging a VPN for everyday coding tasks seems excessive.

One possible solution is to enforce a revocation policy (daily, weekly, every 48 hours, whatever) in which all PATs in a SAML SSO org are revoked. This would require a deverloper to update her access token periodically. This project attempts to solve a portion of this problem via a command line script which deletes all PATs in an SAML SSO org or just PATs fo certain users.

## Usage
### To list tokens, run this command:
`> bundle exec bin/revoker.rb -l ORGNAME`
### To revoke tokens, run this command:
`> bundle exec bin/revoker.rb -r ORGNAME`
### To revoke a specific user's token, run this command:
`> bundle exec bin/revoker.rb -r ORGNAME SOMENAME`

```
Usage: bundle exec bin/revoker.rb [options]
   -v, --verbose                    Show extra information
   -h, --help                       Show this message
   -r, --revoke ORG                 Revokes all SAML SSO tokens for users in a given org
   -n, --name NAME                  Revokes SAML SSO token for named user in a given org
   -l, --list ORG                   List all SAML SSO tokens for users in a given org
```

## Getting the code
`> git clone https://github.com/ngngsoftorg/git_pat_revoker.git`

## Installing the code
```
> rbenv shell 3.0.0
> bundle install
```



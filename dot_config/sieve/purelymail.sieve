# Server-side filter for hi@mikelvillota.com on Purelymail (ManageSieve).
# Source of truth lives here. Deploy (password = gpg file, never on the CLI):
#   gpg -dq ~/.config/mail/purelymail.asc | nix shell nixpkgs#sieve-connect -c \
#     sieve-connect --server mailserver.purelymail.com --port 4190 \
#       --user hi@mikelvillota.com --passwordfd 0 \
#       --upload --localsieve ~/.config/sieve/purelymail.sieve --remotesieve github
#   (same command with --activate --remotesieve github to switch it on)
#
# GitHub notifications: keep the ones that need action in INBOX (and so in
# Gmail's POP3 fetch), file the rest, already read, in the "GitHub" folder.
# Reasons: https://docs.github.com/en/subscriptions-and-notifications/reference/email-notification-headers
require ["fileinto", "mailbox", "imap4flags"];

if address :is "from" "notifications@github.com" {
    if header :is "X-GitHub-Reason" ["mention", "review_requested", "team_mention", "assign", "security_alert"] {
        keep;
        stop;
    }
    addflag "\\Seen";
    fileinto :create "GitHub";
    stop;
}

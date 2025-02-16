if type keychain > /dev/null; then
  keychain ~/.ssh/github_rsa
  source ~/.keychain/$HOST-sh
fi

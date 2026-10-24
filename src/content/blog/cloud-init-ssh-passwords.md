---
title: "I disabled SSH passwords. cloud-init disagreed."
date: 2026-10-07
excerpt: "On a fresh Ubuntu VPS, two drop-in files disagreed about PasswordAuthentication, and the one I didn't know about won. sshd's first-value-wins rule, and how to check what's really in effect."
tags: ["security", "self-hosting"]
draft: false
---

I thought I had turned off SSH passwords on my VPS, and it turned out I hadn't. I'm going to give away the solution first: one small drop-in file of my own, `00-hardening.conf`, because sshd keeps the first value it reads. The rest of the post is how I got there.

Table of contents

1. The setup
2. What the logs showed
3. The cause: two files, one setting
4. The fix
5. Check the effective config, not the files
6. Don't lock yourself out

## The setup

A fresh Contabo VPS, Ubuntu 24.04. One of the first things I did was the usual checklist: a non-root user with sudo, root login disabled, SSH keys. Done, or so I thought.

Weeks later a deploy script asked me for a password. The script's own header said it required key-based access, but the server disagreed: it offered my key, rejected it, and happily fell back to a password prompt.

## What the logs showed

The key problem turned out to be boring: the key simply wasn't in `authorized_keys` for my user. While checking that, though, `journalctl -u ssh` showed something more interesting: a steady stream of `Failed password for root` from IPs I'd never seen, a few seconds apart.

Root login was already disabled. sshd still logs a failed password attempt for root, it just never lets it succeed, so the log line alone doesn't tell you root is exposed (worth knowing before you panic!).

The worse part: password authentication was on. Bots weren't getting in, but every account with a password was a target, and the only thing standing between them and my server was password strength.

## The cause: two files, one setting

On Ubuntu, `/etc/ssh/sshd_config` starts with:

```
Include /etc/ssh/sshd_config.d/*.conf
```

On my box, that directory had two files that contradicted each other:

```
50-cloud-init.conf          → PasswordAuthentication yes
60-cloudimg-settings.conf   → PasswordAuthentication no
```

cloud-init writes the first one from the provider's configuration when the machine is provisioned. The second ships with the Ubuntu cloud image: it's the image's default, and it says no passwords.

Most config systems I know work as "last one wins": read everything, and later values override earlier ones. sshd does the opposite: for most options, the first value it reads wins, and the drop-ins are read in alphabetical order. So `50-` beats `60-`, and passwords were on.

That's by design. The Ubuntu image file used to be called `10-cloudimg-settings.conf`, and it was renamed to `60-` precisely so that it's read *after* cloud-init's `50-` file, letting cloud-init's settings take precedence. The image default is "no passwords", but whatever the provider asks cloud-init to configure wins. My provider asked for passwords. My guess: so new customers can log in with the root password from the welcome email.

So nothing was actually broken: I just never looked at what the provider had decided for me.

## The fix

Don't edit the cloud-init file, because cloud-init can rewrite it. Instead, add a file that sorts first:

```bash
sudo tee /etc/ssh/sshd_config.d/00-hardening.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
EOF
sudo sshd -t && sudo systemctl reload ssh
```

`00-` is read before everything else, so it wins. All my hardening now lives in one file I own, and package or cloud-init updates don't touch it.

## Check the effective config, not the files

Reading config files tells you what someone *wrote*. `sshd -T` tells you what sshd *uses*:

```bash
sudo sshd -T | grep -Ei 'passwordauthentication|kbdinteractive|permitrootlogin'
```

Then test it from the outside, because that's what attackers see:

```bash
ssh -o PubkeyAuthentication=no user@server   # must fail: Permission denied (publickey)
```

## Don't lock yourself out

Before turning off passwords:

1. Make sure your key works: you should log in without a password prompt.
2. Have an out-of-band way in. Most providers offer a web or VNC console that doesn't go through sshd. Test it *before* you need it: credentials, keyboard layout, whether it's even enabled.
3. Keep your current SSH session open while you reload, and test from a new terminal.
4. Think about your other devices. Once passwords are off, adding a new machine's key means going through a device that's already authorized, or through the console.

## Takeaways

- On cloud images, your SSH config isn't just `sshd_config`. Look at `sshd_config.d/`, and assume your provider put something there.
- sshd is first-value-wins, so put your overrides in a `00-` file.
- `sshd -T` is the source of truth. Test from outside with password auth forced.
- `Failed password for root` doesn't mean root login is allowed.

Thanks for reading!

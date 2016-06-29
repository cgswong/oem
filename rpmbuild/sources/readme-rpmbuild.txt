Oracle Enterprise Manager RPM Build
=======================================

The following source files are required in this directory for a successful RPM build:

  - emagent-limits.conf
    - Should be stored under /etc/security/limits.d
    - Provides security limits for EM Agent user
    
  - emagent.sudo
    - Should be stored under /etc/sudoers.d
    - Provides sudo settings for EM Agent user

  - emagent.pam
    - Should be stored under /etc/pam.d
    - Provides PAM settings for EM Agent user

  - emagentlog.lr
    - Should be stored under /etc/logrotate.d
    - Provides logrotate settings for EM related log files    
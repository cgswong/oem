# Oracle Enterprise Manager Configuration

The following configuration files are required for the successful and stable setup of
the Oracle Enterprise Manager (OEM) 12c software stack:

  - emagent-limits.conf
    - Should be stored under /etc/security/limits.d
    - Provides security limits for EM Agent user
    
  - emagent.sudo
    - Should be stored under /etc/sudoers.d
    - Provides sudo settings for EM Agent user

  - emagent-pam
    - Should be stored under /etc/pam.d
    - Provides PAM settings for EM Agent user

  - emlog.lr
    - Should be stored under /etc/logrotate.d
    - Provides logrotate settings for EM related log files
  
## To Do
1. Automated process of distribution such as integration into a Configuration Management system,
  RPM file distribution or scripted process.

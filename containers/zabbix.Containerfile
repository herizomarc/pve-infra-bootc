# ===============================================================
# RED HAT BOOTC IMMUTABLE SOVEREIGN ZABBIX APPLIANCE (IMAGE MODE)
# ===============================================================
FROM registry.redhat.io/rhel9/rhel-bootc:latest

# PHASE 1: PROXMOX CLOUD-INIT & GUEST AGENT INTEGRATION

RUN dnf install -y \
      cloud-init \
      cloud-utils-growpart \
      qemu-guest-agent && \
    systemctl enable \
      cloud-init.service \
      cloud-init-local.service \
      cloud-config.service \
      cloud-final.service \
      qemu-guest-agent.service && \
    dnf clean all


# PHASE 2: REPOSITORIES & METADATA INJECTION
RUN dnf install -y https://repo.zabbix.com/zabbix/7.0/rhel/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm && \
    dnf clean all

# PHASE 3: APPLICATION PACKAGING (ZABBIX ENGINE, POSTGRESQL, WEB & LOCALES)
RUN dnf install -y \
    zabbix-server-pgsql \
    zabbix-web-pgsql \
    zabbix-nginx-conf \
    zabbix-sql-scripts \
    zabbix-selinux-policy \
    zabbix-agent2 \
    postgresql-server \
    firewalld \
    glibc-langpack-en \
    glibc-langpack-fr \
    && dnf clean all


# PHASE 4:SELINUX HARDENING & CUSTOM MODULE FOR ZABBIX KRB5 KEYTAB LOOKUPS
RUN setsebool -P zabbix_can_network on && \
    setsebool -P httpd_can_connect_zabbix on && \
    printf 'module zabbix_krb5 1.1;\nrequire {\n  type zabbix_t;\n  type krb5_keytab_t;\n  class dir { search read open getattr };\n  class file { read open getattr };\n}\nallow zabbix_t krb5_keytab_t:dir { search read open getattr };\nallow zabbix_t krb5_keytab_t:file { read open getattr };\n' > /tmp/zabbix_krb5.te && \
    checkmodule -M -m -o /tmp/zabbix_krb5.mod /tmp/zabbix_krb5.te && \
    semodule_package -o /tmp/zabbix_krb5.pp -m /tmp/zabbix_krb5.mod && \
    semodule -i /tmp/zabbix_krb5.pp && \
    rm -f /tmp/zabbix_krb5.* && \
    dnf clean all


# PHASE 5: SYSTEMD LIFECYCLE MANAGEMENT & RUNTIME ACTIVATION
RUN systemctl enable firewalld && \
    systemctl enable postgresql && \
    systemctl enable zabbix-server && \
    systemctl enable zabbix-agent2 && \
    systemctl enable nginx && \
    systemctl enable php-fpm

# PHASE 6: NETWORK SECURITY ISOLATION BOUNDARIES
EXPOSE 80 443 10051

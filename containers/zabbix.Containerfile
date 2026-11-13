# ===============================================================
# RED HAT BOOTC IMMUTABLE SOVEREIGN ZABBIX APPLIANCE (IMAGE MODE)
# ===============================================================
FROM registry.redhat.io/rhel9/rhel-bootc:latest

# PHASE 1: Cloud-Init & QEMU Guest Agent
RUN dnf install -y cloud-init qemu-guest-agent && \
    systemctl enable cloud-init qemu-guest-agent && \
    dnf clean all

# PHASE 2: REPOSITORIES & METADATA INJECTION
RUN dnf install -y https://repo.zabbix.com/zabbix/7.0/rhel/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm && \
    dnf clean all

# PHASE 3: APPLICATION PACKAGING (ZABBIX ENGINE, POSTGRESQL & WEB LAYER)
RUN dnf install -y \
    zabbix-server-pgsql \
    zabbix-web-pgsql \
    zabbix-nginx-conf \
    zabbix-sql-scripts \
    zabbix-selinux-policy \
    postgresql-server \
    firewalld \
    && dnf clean all

# PHASE 4: SYSTEMD LIFECYCLE MANAGEMENT & RUNTIME ACTIVATION
RUN systemctl enable firewalld && \
    systemctl enable postgresql && \
    systemctl enable zabbix-server && \
    systemctl enable nginx && \
    systemctl enable php-fpm

# PHASE 5: NETWORK SECURITY ISOLATION BOUNDARIES
EXPOSE 80 443 10051

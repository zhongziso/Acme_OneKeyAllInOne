#!/bin/bash

ssl_cert_issue() {
    echo ""
    echo "******使用说明******"
    echo "该脚本将使用Acme脚本申请证书,使用时需保证:"
    echo "1.知晓Cloudflare 注册邮箱"
    echo "2.知晓Cloudflare Global API Key"
    echo "3.域名已通过Cloudflare进行解析到当前服务器"
    echo "4.该脚本申请证书默认安装路径为/root/cert目录"
    
    # 使用 read 进行确认
    read -p "我已确认以上内容[y/n]:" confirm_choice
    if [[ "$confirm_choice" == "y" ]]; then
        cd ~
        echo "安装Acme脚本"
        curl https://get.acme.sh | sh
        if [ $? -ne 0 ]; then
            echo "安装acme脚本失败"
            exit 1
        fi
        
        CF_Domain=""
        CF_GlobalKey=""
        CF_AccountEmail=""
        certPath=/root/cert
        
        # 创建证书目录
        if [ ! -d "$certPath" ]; then
            mkdir $certPath
        else
            rm -rf $certPath
            mkdir $certPath
        fi
        
        # 读取域名
        echo "请设置域名:"
        read -p "Input your domain here: " CF_Domain
        echo "你的域名设置为: ${CF_Domain}"
        
        # 读取API密钥
        echo "请设置API密钥:"
        read -p "Input your key here: " CF_GlobalKey
        echo "你的API密钥为: ${CF_GlobalKey}"
        
        # 读取注册邮箱
        echo "请设置注册邮箱:"
        read -p "Input your email here: " CF_AccountEmail
        echo "你的注册邮箱为: ${CF_AccountEmail}"
        
        ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        if [ $? -ne 0 ]; then
            echo "修改默认CA为Lets'Encrypt失败,脚本退出"
            exit 1
        fi
        
        export CF_Key="${CF_GlobalKey}"
        export CF_Email=${CF_AccountEmail}
        ~/.acme.sh/acme.sh --issue --dns dns_cf -d ${CF_Domain} -d *.${CF_Domain} --log
        if [ $? -ne 0 ]; then
            echo "证书签发失败,脚本退出"
            exit 1
        else
            echo "证书签发成功,安装中..."
        fi
        
        ~/.acme.sh/acme.sh --installcert -d ${CF_Domain} -d *.${CF_Domain} --ca-file /root/cert/ca.cer \
        --cert-file /root/cert/${CF_Domain}.cer --key-file /root/cert/${CF_Domain}.key \
        --fullchain-file /root/cert/fullchain.cer
        if [ $? -ne 0 ]; then
            echo "证书安装失败,脚本退出"
            exit 1
        else
            echo "证书安装成功,开启自动更新..."
        fi
        
        ~/.acme.sh/acme.sh --upgrade --auto-upgrade
        if [ $? -ne 0 ]; then
            echo "自动更新设置失败,脚本退出"
            ls -lah cert
            chmod 755 $certPath
            exit 1
        else
            echo "证书已安装且已开启自动更新,具体信息如下"
            ls -lah cert
            chmod 755 $certPath
        fi
    fi
}
ssl_cert_issue

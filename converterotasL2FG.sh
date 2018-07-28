#!/bin/bash
# Script para Migrar roteamento Linux para Fortigate.
#
# Funcoes 
# 1 - Ler o arquivo de interfaces que contem o roteamento Linux e imprimir na tela as rotas no padrao Fortigate.
# 2 - Ler o diretorio de IPSEC e imprimir na tela as rotas no padrao Fortigate.
# Obs: Nenhum arquivo sera alterado
#
# Sergi A. Martao 01/12/2015

function MAIN()
{

# Caminho do arquivo de interfaces onde contem o roteamento.
# Exemplo interface='/etc/networking/interfaces'
interfaces=''

# Caminho do diretorio que contem as configuracoes de das VPNs IPsec.
# Exemplo ipsec='/etc/ipsec.d'
ipsec=''

# Interface para ignorar o roteamento, caso nao precise, deixe em branco.
# Exemplo ieth=eth0
ieth=

# Contador de numero de rotas.
e=0

# Verificar se a string a cima esta vazia ou nao
if [ -z $ieth ];then iface="stringvazia"; else iface=$ieth;fi

# Filtrando apenas as rotas do arquivo interface
# 1° | Procura a palavra route no arquivo interface
# 2° | Ignora rotas rotas comentadas ou que contenha a palavra rule, realm ou true
# 3° | Remove o exceco de espaço simples
# 4° | Substitui espaço em branco por virgual
# 5° | Remove o excesso de espaço
# 6° | Ignora a interface desejada
# Exemplo da saida de cada linha de rotas
#up,route,add,-host,192.168.230.120,gw,10.10.10.240,eth3,#,cliente,xpto
ROTAS=`grep route $interfaces | grep -ivE "rule|realm|true|^#" | tr -s ' '| sed 's/ /,/g' | sed 's/[[:blank:]]//g' | grep -vi $iface`

# Variavel para controle de impressao na tela, p=1 para rotas com gateway p=2 rotas para interfaces vpn.
p=1

# Loop que lera linha por linha do arquivo interfaces e mostrar no padrao do fortigate.
for a in $ROTAS
do
	# Filtrando apenas a rota Ex 200.200.200.0
	route=`echo $a | cut -d, -f 5 | cut -d/ -f 1`
	# Filtrando apenas a mascara de rede do Linux Ex: 20, 21, etc
	mask=`echo $a | cut -d, -f 5 | grep \/ | cut -d/ -f 2`
	# Filtrando o IP do Gateway  da rota
	gw=`echo $a | cut -d, -f 7`
	# Filtrando a interface da rota ethx
	dev=`echo $a  | cut -d, -f 8,9 | grep -o eth.`
	# Comentario caso exista # rota para client B
	comment=`echo $a | cut -d# -f2 | sed "s/,/ /g" | grep -iv "up route"`
	# Funcao converter nomes de interface Linux para Fortigate
	LOOKUP-DEV		
	# Funcao para converter CIDR para nestmaks do interfaces
	LOOKUP-MASK		
	# Funcao imprimir na tela
	ECHO-SET
done
p=2
# Loop que lerá os arquivos de IPSEC filtrando todas as rightsubnet.
for b in `grep -iEr "rightsu" $ipsec | grep -i \/ipsec | grep -vi "no_oe" | tr -s ' ' | sed 's/ /,/g'`
do
	route=`echo $b | cut -d= -f 2 | cut -d / -f 1`
	mask=`echo $b | cut -d= -f 2 | cut -d / -f 2`
	comment=`echo $b | cut -d. -f 2 | cut -d: -f1`
	vpn=$comment
	tipo="vpn-"
	LOOKUP-MASK
	LOOKUP-DEV-VPN		
	ECHO-SET
done
}
function ECHO-SET()
{
echo " 	edit $((e=$e+1))"
echo " 		set dst $route $maskmod"
# Caso seja a parte 1 deve usar gateway e dispostivo ethX.
if [ $p -eq 1 ];then
	echo "		set gateway $gw"
	echo '		set device "'$devmod'"'
# Se nao apenas a interface VPN do fortigate. (ja deve estar criada)
else
	echo '		set device "'$vpnmod'"'
fi
echo '		set comment "'$tipo$comment'"' 
echo "	next"
}
function LOOKUP-DEV()
{
# Lookup para converter as interfaces Linux para interface Fortigate
case $dev in
	eth0) devmod="wan1";;
	eth1) devmod="port1";;
	eth2) devmod="port4";;
	eth3) devmod="port6";;
	*) devmod="wan1";;
esac
}
function LOOKUP-DEV-VPN()
{
# Lookup converter o nome do arquivo ipsec para o nome da interface
case $vpn in
	xpto) vpnmod="VPN-XPTO";;
	acme) vpnmod="VPN-ACME";;
	tux) vpnmod="VPN-TUX";;
	sardenha) vpnmod="VPN-SARDENHA";;
	vol) vpnmod="VPN-VOL";;
esac
}
function LOOKUP-MASK()
{
# Lookup de mascara de rede, o Linux utiliza /20, /21 e etc...
# O Fortigate precisa escrever a mascara completa /20=255.255.240.0.
case $mask in
	8) maskmod="255.0.0.0";;
	9) maskmod="255.128.0.0";;
	10) maskmod="255.192.0.0";;
	11) maskmod="255.224.0.0";;
	12) maskmod="255.240.0.0";;
	13) maskmod="255.248.0.0";;
	14) maskmod="255.252.0.0";;
	15) maskmod="255.254.0.0";;
	16) maskmod="255.255.0.0";;
	17) maskmod="255.255.128.0";;
	18) maskmod="255.255.192.0";;
	19) maskmod="255.255.224.0";;
	20) maskmod="255.255.240.0";;
	21) maskmod="255.255.248.0";;
	22) maskmod="255.255.252.0";;
	23) maskmod="255.255.254.0";;
	24) maskmod="255.255.255.0";;
	25) maskmod="255.255.255.128";;
	26) maskmod="255.255.255.192";;
	27) maskmod="255.255.255.224";;
	28) maskmod="255.255.255.240";;
	29) maskmod="255.255.255.248";;
	30) maskmod="255.255.255.252";;
	*) maskmod="255.255.255.255";;	
esac
}
MAIN
exit;

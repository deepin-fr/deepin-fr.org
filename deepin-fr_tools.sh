#!/bin/bash
#
# DESC : Boite-a-outils Deepin-FR
# Vers : 2.7
# Date : 19/04/2016
# Auth : Kayoo (http://forum.deepin-fr.org/index.php?p=/profile/6/kayoo)
#
# Utilisation : bash <(wget https://raw.githubusercontent.com/kayoo123/deepin-fr.org/master/deepin-fr_tools.sh -O -)
# Information : https://github.com/kayoo123/deepin-fr.org
###############
sleep 1
###############
## FONCTIONS ##
###############

## COULEUR 
blanc='\e[1;37m'
bleu='\e[1;34m'
vert='\e[1;32m'
jaune='\e[1;33m'
rouge='\e[1;31m'
titre='\e[0;100m'
fin='\e[0;m'

## Vérifie que la commande précédente s'éxécute sans erreur 
function ERROR { 
  if [ ! $? -eq 0 ]; then
    echo ""
    echo -e "${rouge}/!\ Erreur:${fin}"
    echo ""
    echo "Une erreure est intervenu dans le script, merci de le signaler directement sur notre forum :"
    echo -e "=> ${blanc}http://forum.deepin-fr.org${fin}"
    echo ""
    exit 1
  fi
}

## Vérifie et install le paquet manquant (Check a faire avant appel du script)
function TEST_BIN() {
  if [ ! $? -eq 0 ]; then
    echo ""
    echo  -e "${jaune}/!\ Attention:${fin}"
    echo "ce script nécessite : $1"
    echo "Installation en cours, veuillez patienter..."
    echo ""; sleep 1
    CHECK_SERVICE apt-get
    sudo apt-get install -y $1
    echo ""; sleep 1
    echo "Intallation de $1 terminé"
  fi
}

## Vérifie qu'aucun processus ne soit déjà lancé
function CHECK_SERVICE() {
  ps -edf |grep $1 |grep -v grep &> /dev/null
  if [ $? -eq 0 ]; then
    echo ""
    echo  -e "${jaune}/!\ Attention:${fin}"
    echo "Un processus est deja en cours d'utilisation : $1"
    echo "Merci de patienter la fin de la tache courante..."
    echo ""; sleep 1
    exit 1
  fi
}

## 1: Vérifie le dépot déclarer dans le "sources.list"
function DEPOT_CHECK {
  echo ""
  echo -e "${titre}1: Affiche votre serveur de dépot actuellement utilisé${fin}"
  echo ""
  echo -e "${blanc}-- Votre dépot actuel:${fin}"
  sleep 1
  cat /etc/apt/sources.list |grep deb |grep -v ^#| awk '{ print $3 }'| uniq; ERROR
}

## 2: Liste les dépots en afficheant les débits de téléchargement
function DEPOT_LIST {
  echo ""
  echo -e "${titre}2: Fait la liste de l'ensemble des dépots disponible et vous affiche les débits de téléchargement associés${fin}"
  echo ""
  curl -V > /dev/null; TEST_BIN curl; ERROR
  echo -e "${blanc}-- Liste :${fin}"
  curl -s http://mirrors.deepin-fr.org/ | xargs -n1 -I {} sh -c 'echo `curl -r 0-102400 -s -w %{speed_download} -o /dev/null {}/ls-lR.gz` {}'; ERROR
}

## 3: Remplace votre dépot par le plus rapide
function DEPOT_REMPLACE {
  echo ""
  echo -e "${titre}3: Remplace le dépot de votre systeme par le plus performant${fin}"
  echo ""
  curl -V > /dev/null; TEST_BIN curl; ERROR
  echo "Veuillez patienter pendant que nous determinons le meilleur dépot pour vous..."
  BEST_REPO=$(curl -s http://mirrors.deepin-fr.org/ | xargs -n1 -I {} sh -c 'echo `curl -r 0-102400 -s -w %{speed_download} -o /dev/null {}/ls-lR.gz` {}' |sort -gr |head -1 |awk '{print $2}'); ERROR
  sudo sh -c 'echo "## Generer par Deepin-fr" > /etc/apt/sources.list'; ERROR
  sudo env BEST_REPO=$BEST_REPO sh -c 'echo "deb [by-hash=force] $BEST_REPO unstable main contrib non-free" >> /etc/apt/sources.list'; ERROR
  echo ""
  echo -e "=> Le fichier de configuration du dépot a été modifié avec ${vert}SUCCES${fin}."
}

## 4: Remplace votre dépot par l'officiel ( seveur en chine)
function DEPOT_RETOUR {
  echo ""
  echo -e "${titre}4: Si vous souhaitez revenir au dépot original : http://packages.deepin.com${fin}"
  echo ""
  echo "Retour sur le dépot original (sans modification)"
  echo "Veuillez patienter..."
  sleep 2
  sudo sh -c 'echo "## Generated by deepin-installer" > /etc/apt/sources.list'; ERROR
  sudo sh -c 'echo "deb [by-hash=force] http://packages.deepin.com/deepin unstable main contrib non-free" >> /etc/apt/sources.list'; ERROR
  sudo sh -c 'echo "#deb-src http://packages.deepin.com/deepin unstable main contrib non-free" >> /etc/apt/sources.list'; ERROR
  echo ""
  echo -e "=> Le fichier de configuration du dépot a été modifié avec ${vert}SUCCES${fin}."
}

## 5: Met a jour du systeme avec correction des dépendances
function MAJ_SYSTEME {
  echo ""
  echo -e "${titre}5: Mise-à-jour de votre systeme Deepin COMPLET${fin}"
  echo ""
  echo -e "${blanc}-- Mise a jour de votre cache:${fin}"
  CHECK_SERVICE apt-get
  sudo apt-get update; ERROR
  echo ""
  echo -e "${blanc}-- Mise a jour de vos paquets:${fin}"
  sudo apt-get -y upgrade; ERROR
  echo ""
  echo -e "${blanc}-- Installation des dépendances manquantes et reconfiguration:${fin}"
  sudo apt-get install -f; ERROR
  sudo dpkg --configure -a; ERROR
  echo ""
  echo -e "${blanc}-- Suppression des dépendances inutilisées:${fin}"
  sudo apt-get -y autoremove; ERROR
  echo ""
  echo ""
  echo -e "=> Votre systeme a été mise-à-jour avec ${vert}SUCCES${fin}."
}

## 6: Nettoie votre systeme en profondeur
function CLEAN_SYSTEME {
  echo ""
  echo -e "${titre}6: Nettoyage de votre systeme Deepin COMPLET${fin}"
  echo ""
  echo -e "${blanc}-- Nettoyage de vos paquets archivés:${fin}"
  CHECK_SERVICE apt-get
  sudo apt-get update; ERROR # cache
  sudo apt-get autoclean; ERROR # Suppression des archives périmées
  sudo apt-get clean; ERROR # Supressions des paquets en cache
  sudo apt-get autoremove; ERROR # Supression des dépendances inutilisées
  echo ""
  echo -e "${blanc}-- Supression des configurations logiciels désinstallées :${fin}"
  dpkg -l | grep ^rc | awk '{print $2}' ; ERROR
  dpkg -l | grep ^rc | awk '{print $2}' |xargs sudo dpkg -P &> /dev/null
  echo ""
  echo -e "${blanc}-- Supression des paquets orphelins:${fin}"
  deborphan -v > /dev/null; TEST_BIN deborphan; ERROR
  sudo deborphan; ERROR
  sudo dpkg --purge $(deborphan) &> /dev/null
  echo ""
  echo -e "${blanc}-- Nettoyage des locales:${fin}"
  sudo sed -i -e "s/#\ fr_FR.UTF-8 UTF-8/fr_FR.UTF-8\ UTF-8/g" /etc/locale.gen; ERROR
  sudo locale-gen; ERROR
  sudo localepurge --help &> /dev/null; TEST_BIN localepurge; ERROR
  sudo localepurge; ERROR
  echo ""
  echo -e "${blanc}-- Nettoyage des images miniatures:${fin}"
  rm -Rf $HOME/.thumbnails/*; ERROR
  echo ""
  echo -e "${blanc}-- Nettoyage du cache des navigateurs:${fin}"
  rm -Rf $HOME/.mozilla/firefox/*.default/Cache/*; ERROR
  rm -Rf $HOME/.cache/google-chrome/Default/Cache/*; ERROR
  rm -Rf $HOME/.cache/chromium/Default/Cache/*; ERROR
  echo ""
  echo -e "${blanc}-- Nettoyage du cache de Flash_Player:${fin}"
  rm -Rf $HOME/.macromedia/Flash_Player/macromedia.com; ERROR
  rm -Rf $HOME/.macromedia/Flash_Player/\#SharedObjects; ERROR
  echo ""
  echo -e "${blanc}-- Nettoyage des fichiers de sauvegarde:${fin}"
  find $HOME -name '*~' -exec rm {} \;; ERROR
  echo ""
  echo -e "${blanc}-- Nettoyage de la corbeille:${fin}"
  rm -Rf $HOME/.local/share/Trash/*; ERROR
  echo ""
  echo -e "${blanc}-- Nettoyage de la RAM:${fin}"
  sudo sysctl -w vm.drop_caches=3 &> /dev/null; ERROR
  free -h
  echo ""
  echo ""
  echo -e "=> Votre systeme a été nettoyé avec ${vert}SUCCES${fin}."
}

## 7: Installation du dictionnaire de la suite WPS-Office
function DICO_FR_WPS {
  echo ""
  echo -e "${titre}7: Installation du dictionnaire Francais pour WPS-Office:${fin}"
  echo ""
  echo -e "${blanc}-- Téléchargement de l'archive:${fin}"
  sudo rm -rf /opt/kingsoft/wps-office/office6/dicts/fr_FR
  wget -P /tmp http://wps-community.org/download/dicts/fr_FR.zip; ERROR
  echo ""
  echo -e "${blanc}-- Décompression de l'archive:${fin}"
  unzip -v &> /dev/null; TEST_BIN unzip; ERROR
  sudo unzip /tmp/fr_FR.zip -d /opt/kingsoft/wps-office/office6/dicts/; ERROR
  rm -f /tmp/fr_FR.zip; ERROR
  echo ""
  echo ""
  echo -e "=> Le dictionnaire Francais a été téléchargé avec ${vert}SUCCES${fin}."
  echo "Il vous suffit de sélectionner dirrectement depuis la suite WPS-Office:"
  echo "Outils > Options > Vérifier l'orthographe > Dictionnaire personnel > Ajouter"
}

## 8: Activation de la touche verr.num au boot
function VERR_NUM_BOOT {
  echo ""
  echo -e "${titre}8: Activation de la touche \"Verrouillage Numérique\" au démarrage:${fin}"
  echo ""
  echo -e "${blanc}-- Téléchargement de numlockx:${fin}"
  numlockx status &> /dev/null; TEST_BIN numlockx; ERROR
  echo ""
  echo -e "${blanc}-- Activation dans la configuration \"lightdm\":${fin}"
  sudo sed -i -e "s#\#greeter-setup-script=#greeter-setup-script=/usr/bin/numlockx\ on#g" /etc/lightdm/lightdm.conf; ERROR
  echo ""
  echo ""
  echo -e "=> La touche \"Verrouillage Numérique\" a été activé au démarrage avec ${vert}SUCCES${fin}."
}

## 9: Telechargement wallpaper : InterfaceLIFT.com
function DL_WALLPAPER {
RESOLUTION=$(xrandr --verbose|grep "*current" |awk '{ print $1 }' |head -1)
DIR=$HOME/Images/Wallpapers
URL_WALLPAPER=http://interfacelift.com/wallpaper/downloads/random/hdtv/$RESOLUTION/
  echo ""
  echo -e "${titre}9: Telechargement de fond d\'ecran : \"InterfaceLIFT.com\":${fin}"
  echo ""
  echo -e "${blanc}-- Detection de vos écrans:${fin}"
  sleep 1; echo "Nous avons détecté une resolution pour votre ecran de : $RESOLUTION"
  echo -e "Confirmez-vous cette résolution ${jaune}[O/n]${fin} ?"
  read REP
  if [ $REP = 'O' ] || [ $REP = 'o' ] || [ $REP = 'Y' ] || [ $REP = 'y' ]; then
  dpkg -l |grep lynx &> /dev/null; TEST_BIN lynx; ERROR
  wget -V &> /dev/null; TEST_BIN wget; ERROR
  echo ""
  echo -e "${blanc}-- Debut du telechargement:${fin}"
  echo ""
  wget -nv --show-progress -U "Mozilla/5.0" -P $DIR $(lynx --dump $URL_WALLPAPER | awk '/7yz4ma1/ && /jpg/ && !/html/ {print $2}'); ERROR
  find $DIR -type f -iname "*.jp*g" -size -50k -exec rm {} \;
  echo ""
  echo -e "${blanc}-- Rechargement du centre de control:${fin}"
  pkill -9 dde-control-cen; ERROR
  echo ""
  echo ""
  echo -e "=> Les nouveaux fond d'écrans ont été telechargé avec ${vert}SUCCES${fin}."
  fi
}



##########
## MAIN ##
##########
clear
echo ""
echo -e "${bleu}  ██████╗ ███████╗███████╗██████╗ ██╗███╗   ██╗      ███████╗██████╗ ${fin}"
echo -e "${bleu}  ██╔══██╗██╔════╝██╔════╝██╔══██╗██║████╗  ██║      ██╔════╝██╔══██╗${fin}"
echo -e "${bleu}  ██║  ██║█████╗  █████╗  ██████╔╝██║██╔██╗ ██║█████╗█████╗  ██████╔╝${fin}"
echo -e "${bleu}  ██║  ██║██╔══╝  ██╔══╝  ██╔═══╝ ██║██║╚██╗██║╚════╝██╔══╝  ██╔══██╗${fin}"
echo -e "${bleu}  ██████╔╝███████╗███████╗██║     ██║██║ ╚████║      ██║     ██║  ██║${fin}"
echo -e "${bleu}  ╚═════╝ ╚══════╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═══╝      ╚═╝     ╚═╝  ╚═╝${fin}"
echo ""
echo "Nous vous proposons a travers ce script de realiser des opérations liées à votre distribution DEEPIN."
echo -e "Ce script est produit dans le cadre d'une assistance sur ${blanc}http://deepin-fr.org${fin}"
echo ""
echo "- Noyaux: $(uname -r)"
echo "- OS : $(source /etc/lsb-release; echo $DISTRIB_DESCRIPTION)"
echo "- Arch : $(uname -m)"
echo ""
echo "Nous vous proposons les taches suivantes :"
echo ""
PS3='=> Choix : '
options=("Liste votre dépot actuel" "Lister les dépots disponibles" "Utiliser le meilleur dépot" "Revenir au dépot original" "Mettre à jour sa distribution PROPREMENT" "Nettoyer sa distribution COMPLETEMENT" "Ajouter le dictionnaire Francais pour WPS-Office" "Activer la touche \"verrouillage numérique\" au démarrage" "Telecharger des fond d\'écran sur InterfaceLIFT.com" "Quitter")
select opt in "${options[@]}"
do
    case $opt in
        "Liste votre dépot actuel")
            DEPOT_CHECK
            ;;
        "Lister les dépots disponibles")
            DEPOT_LIST
            ;;
        "Utiliser le meilleur dépot")
            DEPOT_REMPLACE
            ;;
        "Revenir au dépot original")
            DEPOT_RETOUR
            ;;
        "Mettre à jour sa distribution PROPREMENT")
            MAJ_SYSTEME
            ;;
        "Nettoyer sa distribution COMPLETEMENT")
            CLEAN_SYSTEME
            ;;
	"Ajouter le dictionnaire Francais pour WPS-Office")
	    DICO_FR_WPS
	    ;;
        "Activer la touche \"verrouillage numérique\" au démarrage")
            VERR_NUM_BOOT
            ;;
        "Telecharger des fond d\'écran sur InterfaceLIFT.com")
            DL_WALLPAPER
            ;;
        "Quitter")
	    echo ""
	    echo "L'équipe de \"Deepin-fr.org\" vous remercie d'avoir utilisé ce script..."
            ;;
        *) echo option invalide;;
    esac
break
done

exit 0

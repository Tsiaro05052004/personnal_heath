# **CAHIER DES CHARGES SIMPLIFIÉ**

## **Application mobile de suivi personnel de santé et de rappels médicaux**

Projet d'application mobile  
Santé et bien-être  
Version 1.0

## **1\. Présentation générale du projet**

### **1.1. Contexte et justification**

La prise de médicaments et le suivi des habitudes quotidiennes liées à la santé sont des éléments importants pour préserver le bien-être d'une personne.

Cependant, certaines personnes oublient de prendre leurs médicaments à l'heure prescrite par leur médecin, ne respectent pas toujours la fréquence de leur traitement ou oublient de boire suffisamment d'eau au cours de la journée.

Par ailleurs, lorsqu'une personne a besoin de soins, elle peut rencontrer des difficultés pour identifier rapidement les hôpitaux ou centres de santé situés à proximité de son emplacement.

Pour répondre à ces besoins, le projet consiste à développer une application mobile personnelle de santé qui permettra à chaque utilisateur de :

- Localiser les hôpitaux et centres de santé proches de lui.
- Enregistrer les médicaments prescrits par son médecin.
- Programmer des rappels pour la prise de ses médicaments.
- Suivre le nombre de médicaments pris au cours de la journée.
- Définir un objectif quotidien de consommation d'eau.
- Suivre sa progression grâce à des compteurs.
- Recevoir des notifications et des alarmes en cas d'oubli ou de retard.

### **1.2. Objectif général**

Développer une application mobile simple et intuitive permettant à chaque utilisateur de mieux organiser son suivi médical quotidien, de respecter les horaires de ses traitements et d'adopter de bonnes habitudes de santé.

### **1.3. Objectifs spécifiques**

L'application devra permettre de :

1. Afficher une carte interactive indiquant les établissements de santé à proximité.
2. Faciliter la recherche et la localisation des hôpitaux.
3. Enregistrer les informations relatives aux médicaments prescrits.
4. Programmer les heures de prise des médicaments.
5. Comptabiliser les prises réellement effectuées.
6. Envoyer des notifications en cas de prise oubliée ou en retard.
7. Suivre la consommation quotidienne d'eau.
8. Afficher un bilan journalier des activités de santé.

## **2\. Description générale des fonctionnalités**

L'application sera organisée autour de quatre grandes fonctionnalités.

### **2.1. Localisation des hôpitaux et centres de santé**

[Healthpal Flutter UI Kit by FlutterFire \| CodeCanyon](https://images.openai.com/static-rsc-4/aKrN3KTgssHkVRXAYm5g7W7zKL0R2cUSDCqg2nEc8AsOWhUiHX_rm5sehM82qJDgDxJ7uAliCS-DlGqsg414f70eR6cBh9G-KOgVzCc3wnHbsqu6S3txO48h1tlfhbqlH4HTVb-TDfBtmfwntZEhUVy76h9xMRJHhnm-m47y89Q?purpose=inline)  
[ScanForLife](https://images.openai.com/static-rsc-4/-Wvu5Eu0ZpgsiT7cMdJgz9UVKTbBy5IyE2tvlBSqhtKu9LBciBIx2oaUiT9oQ5KNUtDUe1y14MVfja4Mp69c9d-Ur3ls-dq-sQlRA9BjEt7wLMtXmZrYvQVimseVf9goMdBH3sJPo8zcmuucthGT6WfkR3pSAD9cLe6fnWiDEFo?purpose=inline)  
[The health of Egypt 'Sahet Misr' App Redesign by Osama Dawood on Dribbble](https://images.openai.com/static-rsc-4/-YHXpT9qJTi_rLPih09nAL8cl2K5_EFY12bPPGwsvnLnY_v_kDstK-C_1aBm4P-x7XYuhWCiEZKmj4TjtolyC3e5Da6-ha_6Krm65Tz5vaIy3a7K5MHHzOtECnRfGXhNArFPGlpWB_Bm_KczqdTp_yS6H1uIgoJxW4N6022mbYM?purpose=inline)  
8

Cette fonctionnalité permettra à l'utilisateur de consulter une carte interactive similaire à Google Maps, mais utilisant les données cartographiques d'OpenStreetMap.

Fonctionnement :

- L'application demande l'autorisation d'accéder à la position géographique de l'utilisateur.
- Elle affiche sa position actuelle sur une carte.
- Elle identifie les hôpitaux, cliniques et centres de santé situés à proximité.
- Chaque établissement est représenté par un marqueur sur la carte.
- Lorsque l'utilisateur clique sur un marqueur, une fiche descriptive apparaît.

Informations affichées pour chaque établissement :

- Nom de l'établissement.
- Adresse ou localisation.
- Type d'établissement (hôpital, clinique, centre de santé, etc.).
- Distance approximative par rapport à l'utilisateur.
- Possibilité d'obtenir un itinéraire pour s'y rendre.
- Numéro de téléphone, lorsqu'il est disponible.

L'utilisateur pourra également rechercher un établissement par son nom ou par sa localisation.

### **2.2. Gestion et suivi des médicaments**

[Medicine Reminder App by Black Leaf Design Studio on Dribbble](https://images.openai.com/static-rsc-4/qTbMMUIIFldUJ4AjrpUu32NKv01KxjMibVQXbSC10StJawK2_xMp_u9q7Yz1z47la7HRw6V77-_OZNi4Eg3IEJm6P9cxpn3ShZoKCCGVeWh0eSp7OqtDaQ8piblRC3pFI-n4y28_uNvx6Xq7CtzbKiPstjMMlFRauMtHS8uu20g?purpose=inline)  
[Medicine Reminder App by Techugo on Dribbble](https://images.openai.com/static-rsc-4/rZnK9E-zP_IB3H1RaVEvmkNNgvoQ7ikOoim16vLSoN7oe-IefbWR04M42ylRZaxVISnzPx0ptyThpw2bsAtow3GMse1GpYvnCQX6g9tx2mEmsAdMN-jsYcKC6rrz-jjzr_wL0ITiwLfFmghZg7y_iZq8JYzFwv8c7mBJN2jNgtE?purpose=inline)  
[Pill Tracker Mobile iOS App by Purrweb UI/UX Agency on Dribbble](https://images.openai.com/static-rsc-4/_PRbb7us7TCfQVaoyhb-s298WtowALnETopPNikpA1iWTiBUB6TlFccPCgB5xhdkvspon3Rx9WmeOAtCj6KsDsf3cmmgliiYOD9S_dnMHJqMbteUj20YG5YvT8e6daAiiGnQ1iudqmmzi1sYaXTexpjyxnBmo5bWKkP7JsGG0RQ?purpose=inline)  
10

Cette fonctionnalité permettra à l'utilisateur d'enregistrer les médicaments qui lui ont été prescrits par son médecin et de suivre leur prise quotidienne.

A. Enregistrement des médicaments

L'utilisateur disposera d'un formulaire contenant les informations suivantes :

| Informations       | Description                                    |
| ------------------ | ---------------------------------------------- |
| Nom du médicament  | Nom du médicament prescrit                     |
| Dosage             | Quantité prescrite (ex. : 500 mg)              |
| Quantité par prise | Nombre de comprimés ou de doses à prendre      |
| Fréquence          | Nombre de prises par jour                      |
| Horaires           | Heures auxquelles le médicament doit être pris |
| Date de début      | Début du traitement                            |
| Date de fin        | Fin prévue du traitement                       |
| Instructions       | Avant ou après le repas, par exemple           |

L'utilisateur pourra ajouter plusieurs médicaments et modifier ou supprimer une prescription enregistrée.

B. Suivi de la prise des médicaments

Chaque médicament enregistré apparaîtra dans une liste quotidienne.

Exemple :

Mon suivi des médicaments

Paracétamol – 500 mg

1 prise sur 3

08h00 : prise effectuée

Pris

14h00 : prochaine prise

En attente

20h00 : dernière prise

À venir  
Confirmer la prochaine prise (exemple)Illustration du fonctionnement attendu.

À chaque fois que l'utilisateur prend effectivement son médicament, il clique sur le bouton « Confirmer la prise ».

Le compteur augmente alors automatiquement et la prise est enregistrée avec la date et l'heure.

C. Système de rappels et d'alertes

L'application devra envoyer une notification à l'heure prévue pour rappeler à l'utilisateur qu'il doit prendre son médicament.

Si l'utilisateur ne confirme pas la prise :

- Une première notification lui rappelle que le médicament doit être pris.
- Si le délai de rappel est dépassé, une deuxième notification peut être envoyée.
- Une alarme sonore pourra être activée si l'utilisateur l'autorise.

Il est important de distinguer une prise oubliée d'une prise simplement non confirmée : l'application ne peut pas savoir si la personne a réellement pris son médicament sans qu'elle le lui indique.

L'utilisateur pourra également signaler une prise effectuée en retard ou une dose oubliée.

### **2.3. Suivi de la consommation quotidienne d'eau**

[HydrateTap](https://images.openai.com/static-rsc-4/YWBY5fgOjAe-1SrxA6i-7nQlF9wzYLQv6sTjfQ6eL50iNK3HUyxclsTySd453mivGlcqIYZvXG3mlhgB2PhQzVEs7hUoM4mSeae1edZXh7FKBCTAmxpHA1QRSSxeBgXca8VPvn_kCsld7zRH6JSuPZ1dQ7c8NbprTsRmkYO1YlA?purpose=inline)  
[Water Reminder App Ui by Argon IT Services LLP on Dribbble](https://images.openai.com/static-rsc-4/adS2tFfV9uDVCbM1YJdeWf8TpBSzHtOeyeSf9v5qcbaGN3HC5V9K4kC_TQ_kwQbOMUwA5VhtvGl1vjz20IiOLUZC-JIUlUOebpV5t9Q6NXplJHq66nNADP-Pe7mQnf4yfRhXD4TT9FEFEkO6IsD4Ezv0hsyeoX1ZnWQQKIjNO90?purpose=inline)  
[Las mejores 8 apps con recordatorios para beber agua](https://images.openai.com/static-rsc-4/o9l12dv2ab0TL9_wONFw2_x5ZeWng9km8u2OjA9uSF0TxL2IzkLivZ7sXAtTJgDySpCwlJILgw6V3t_LpmiwDCYlTR-JgXTQ4vQV96LraZZkBI25hi6BzuHa5iGgY3g6Jmbo1rVI6U8kjtV7sGYLdtbby2N0XMYM-1-EX16hppc?purpose=inline)  
6

Cette fonctionnalité permettra à l'utilisateur de définir un objectif personnel de consommation d'eau par jour.

A. Définition de l'objectif

Au début de l'utilisation, l'utilisateur pourra définir :

- Son objectif quotidien (ex. : 5 verres par jour).
- La quantité correspondant à un verre (ex. : 250 ml).
- Ses horaires habituels de réveil et de coucher, pour organiser les rappels.

B. Comptabilisation de l'eau consommée

L'application affichera un compteur permettant de suivre la progression.

Mon objectif quotidien d'eau

# **3 / 5**

Verres consommés

Bu  
Bu  
Bu  
À boire  
À boire  
\+ Ajouter un verre (exemple)Illustration du compteur d'hydratation.

Chaque fois que l'utilisateur boit un verre d'eau, il clique sur le bouton « Ajouter un verre ».

Le compteur augmente automatiquement.

C. Rappels et notifications

Si l'utilisateur n'a pas atteint son objectif quotidien, l'application pourra lui envoyer des rappels à des moments définis de la journée.

Par exemple :

- À 10h00 : rappel pour boire de l'eau.
- À 13h00 : rappel si l'objectif intermédiaire n'est pas atteint.
- À 17h00 : notification indiquant le nombre de verres restants.

À l'approche de la fin de la journée, l'application pourra afficher une notification indiquant si l'objectif a été atteint ou non.

L'objectif est d'encourager l'utilisateur à boire régulièrement, et non de l'inciter à boire une grande quantité d'eau d'un seul coup. Les objectifs devront rester personnalisables et adaptés aux besoins de chacun.

### **2.4. Tableau de bord et bilan quotidien**

[Dosely \| Medication Reminder & Family Care](https://images.openai.com/static-rsc-4/Fqv4sclA-l7rlx-OElM_LiwGX9a5qBCezscZlSbkAsyG4a6K3pfNAVoHH7nvtQGTT7HaETu8dinVNqCk68nXWQl05aB6EjXeugkYB05550h1YtfLq-GvDhGFTkx9WhehC35bmutTxZixiM5fWffrCewUqMInwqHsg3zRDa-kLSM?purpose=inline)  
[mydosely.com](https://www.mydosely.com/?utm_source=chatgpt.com)

L'application disposera d'un tableau de bord principal qui regroupera les informations essentielles de la journée.

L'utilisateur pourra consulter :

- Le nombre de médicaments prévus.
- Le nombre de prises confirmées.
- Les médicaments en attente.
- Les prises en retard ou non confirmées.
- Le nombre de verres d'eau consommés.
- Le niveau de progression de son objectif d'hydratation.

Un bilan quotidien permettra à l'utilisateur de voir s'il a respecté son programme de suivi.

## **3\. Organisation et navigation de l'application**

L'application devra être simple à utiliser, même pour une personne qui n'a pas de connaissances particulières en informatique.

Elle comportera les interfaces principales suivantes :

Accueil – Tableau de bord

Médicaments

Suivi des prises et rappels

Hydratation

Compteur de consommation d'eau

Hôpitaux

Carte des établissements de santé

Historique

Bilans et suivi des activités

Navigation principale illustrative

L'application comportera les pages suivantes :

| Page                    | Rôle                                      |
| ----------------------- | ----------------------------------------- |
| Connexion / Inscription | Créer un compte ou accéder à son compte   |
| Accueil                 | Consulter le résumé quotidien             |
| Carte                   | Localiser les hôpitaux proches            |
| Mes médicaments         | Ajouter et gérer les prescriptions        |
| Suivi des médicaments   | Confirmer les prises                      |
| Hydratation             | Suivre la consommation d'eau              |
| Historique              | Consulter les anciens bilans              |
| Paramètres              | Configurer les notifications et le profil |

## **4\. Déroulement général de l'utilisation**

Voici comment un utilisateur utilisera l'application depuis sa première connexion.

1. Création du compte  
   L'utilisateur crée son compte en renseignant les informations nécessaires, comme son nom, son adresse e-mail et son mot de passe.
2. Accès à l'accueil  
   Il arrive sur le tableau de bord qui présente les fonctionnalités principales de l'application.
3. Localisation  
   Il peut ouvrir la carte pour consulter les établissements de santé à proximité de sa position.
4. Enregistrement du traitement  
   Il renseigne les médicaments prescrits par son médecin, les dosages, les horaires et la durée du traitement.
5. Configuration des objectifs d'eau  
   Il définit son objectif quotidien de consommation d'eau.
6. Suivi quotidien  
   Il confirme chaque prise de médicament et chaque verre d'eau consommé.
7. Réception des notifications  
   L'application lui envoie des rappels selon les horaires et les objectifs configurés.
8. Consultation du bilan  
   Il consulte son historique et vérifie sa progression quotidienne.

## **5\. Les utilisateurs concernés**

L'application est principalement destinée aux personnes souhaitant mieux organiser leur suivi personnel de santé.

Les utilisateurs potentiels sont :

- Les personnes qui suivent un traitement médical.
- Les personnes qui prennent plusieurs médicaments par jour.
- Les personnes âgées ayant besoin de rappels réguliers.
- Les personnes souhaitant améliorer leur consommation quotidienne d'eau.
- Toute personne souhaitant centraliser certaines informations relatives à son suivi de santé.

## **6\. Contraintes et exigences du projet**

Pour assurer le bon fonctionnement de l'application, certaines exigences devront être respectées.

### **6.1. Contraintes techniques**

- L'application devra fonctionner sur Android et, idéalement, sur iOS.
- La carte devra utiliser OpenStreetMap.
- La géolocalisation devra fonctionner avec l'autorisation de l'utilisateur.
- Les notifications devront pouvoir apparaître même lorsque l'application est fermée.
- Les alarmes devront être configurables par l'utilisateur.
- Les données devront être enregistrées de manière sécurisée.
- L'application devra être facile à utiliser et ne pas nécessiter une connexion Internet permanente pour les fonctionnalités de suivi déjà configurées.

### **6.2. Contraintes liées aux notifications**

Il faudra prévoir un système capable de gérer les rappels selon les horaires définis.

Un point important : une notification ne garantit pas que l'utilisateur la verra. Le téléphone peut être éteint, en mode silencieux ou avoir des restrictions sur les notifications.

L'application devra donc proposer des rappels fiables, tout en expliquant à l'utilisateur qu'il doit autoriser les notifications et les alarmes.

### **6.3. Sécurité et confidentialité**

Les informations médicales étant personnelles et confidentielles, l'application devra garantir :

- La protection des informations personnelles.
- La sécurisation des mots de passe.
- L'accès aux données uniquement par leur propriétaire.
- La protection des informations relatives aux traitements médicaux.
- La possibilité de supprimer son compte et ses données.
- Une gestion claire des autorisations de localisation et de notifications.

## **7\. Règles de gestion importantes**

Pour éviter les incohérences dans le fonctionnement de l'application, certaines règles devront être respectées.

| Situation                                       | Comportement attendu                                       |
| ----------------------------------------------- | ---------------------------------------------------------- |
| L'utilisateur confirme une prise                | Le compteur augmente d'une prise                           |
| L'utilisateur ne confirme pas une prise         | La prise reste non confirmée et un rappel peut être envoyé |
| L'utilisateur confirme une prise en retard      | La prise est enregistrée avec son heure réelle             |
| Le traitement arrive à sa date de fin           | Les rappels du traitement s'arrêtent                       |
| L'utilisateur ajoute un verre d'eau             | Le compteur d'eau augmente                                 |
| L'objectif d'eau est atteint                    | L'application affiche un message de réussite               |
| La journée se termine sans atteindre l'objectif | L'application affiche un bilan de l'objectif non atteint   |
| L'utilisateur modifie son traitement            | Les nouveaux horaires sont pris en compte                  |

Une règle médicale essentielle : l'application est un outil de rappel et de suivi, et non un médecin. Elle ne doit jamais modifier automatiquement les doses, conseiller de doubler une prise oubliée ou remplacer les instructions du professionnel de santé.

Pour éviter les erreurs, il faudra aussi distinguer le nombre de prises du nombre de comprimés. Par exemple, une personne peut prendre deux comprimés à une seule heure de prise : cela compte comme une prise, mais deux comprimés consommés.

## **8\. Fonctionnalités prévues pour la première version (MVP)**

Pour faciliter le développement et éviter de rendre le projet trop complexe dès le début, il est préférable de commencer avec une première version qui contient uniquement les fonctionnalités essentielles.

| Fonctionnalité                           | Priorité      |
| ---------------------------------------- | ------------- |
| Création de compte et connexion          | Indispensable |
| Tableau de bord                          | Indispensable |
| Carte des hôpitaux avec OpenStreetMap    | Indispensable |
| Ajout et gestion des médicaments         | Indispensable |
| Programmation des horaires de prise      | Indispensable |
| Notifications et alarmes                 | Indispensable |
| Compteur de prises de médicaments        | Indispensable |
| Objectif quotidien de consommation d'eau | Indispensable |
| Compteur de verres d'eau                 | Indispensable |
| Historique journalier                    | Important     |
| Statistiques hebdomadaires et mensuelles | Évolution     |
| Partage du suivi avec un proche          | Évolution     |
| Connexion avec un professionnel de santé | Évolution     |

## **9\. Améliorations possibles dans les versions futures**

Après la réalisation de la première version, plusieurs fonctionnalités pourront être ajoutées :

- Gestion des proches : permettre à un proche de suivre les rappels et les prises d'un membre de sa famille, avec son autorisation.
- Gestion des ordonnances : permettre de prendre une photo d'une ordonnance pour faciliter l'enregistrement des médicaments, avec vérification humaine des informations.
- Suivi des rendez-vous médicaux : enregistrer les rendez-vous chez le médecin et recevoir des rappels.
- Rapports de suivi : générer un rapport hebdomadaire ou mensuel que l'utilisateur pourra partager avec son médecin.
- Gestion des stocks de médicaments : avertir l'utilisateur lorsque son stock de médicaments devient faible.
- Personnalisation avancée : adapter les notifications et les objectifs aux habitudes de l'utilisateur.

## **10\. Résultat attendu**

À la fin du projet, nous souhaitons obtenir une application mobile personnelle de santé qui permettra à l'utilisateur de centraliser plusieurs activités quotidiennes liées à son bien-être.

Grâce à cette application, l'utilisateur pourra retrouver facilement les établissements de santé à proximité, gérer ses médicaments, recevoir des rappels pour ses traitements, suivre sa consommation d'eau et consulter ses progrès.

L'application devra avant tout être simple, pratique, intuitive et accessible à tous.

## **11\. Conclusion**

Ce projet vise à proposer une solution numérique qui accompagne les utilisateurs dans leur quotidien en leur permettant de mieux respecter leurs prescriptions médicales et de suivre leurs habitudes de santé.

L'objectif n'est pas de remplacer les professionnels de santé, mais de mettre à la disposition de chacun un assistant personnel qui facilite l'organisation et le suivi de ses activités médicales quotidiennes.

## **12\. Proposition d'orientation technique (indicative)**

Pour donner une première direction au développement, voici les technologies qui pourraient être utilisées :

| Élément                  | Technologie proposée                              |
| ------------------------ | ------------------------------------------------- |
| Application mobile       | Flutter                                           |
| Carte interactive        | OpenStreetMap                                     |
| Affichage cartographique | Flutter Map                                       |
| Géolocalisation          | GPS du téléphone                                  |
| Base de données          | Supabase ou Firebase                              |
| Authentification         | Supabase Auth ou Firebase Auth                    |
| Notifications locales    | Système de notifications Flutter                  |
| Alarmes                  | Gestion des alarmes et notifications du téléphone |

Ces technologies sont des propositions et pourront être adaptées selon les compétences de l'équipe de développement.

Remarque : les données cartographiques d'OpenStreetMap sont utilisables, mais il faudra choisir un fournisseur de tuiles cartographiques adapté et respecter ses conditions d'utilisation. Les informations sur les hôpitaux devront également être vérifiées, car leur présence sur la carte ne garantit pas que leurs coordonnées ou leurs services soient à jour.

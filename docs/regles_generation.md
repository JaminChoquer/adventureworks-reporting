# Règles de génération des données complémentaires

Ce document décrit comment chaque fichier est produit par `generator/generate_complements.py`. Le générateur est déterministe (graine `20251009`) : deux exécutions donnent exactement les mêmes fichiers. Tous les paramètres cités ici figurent en tête de leur section dans le code.

## 1. Principe

Le jeu ne tire rien « au hasard pur ». Chaque volume découle d'une **exposition** tirée d'AdventureWorks (salariés, équipes, heures de production, commandes), multipliée par des **taux de référence** et des **facteurs de contexte** documentés ci-dessous. Les données restent donc cohérentes entre elles : un atelier chargé fait plus d'heures supplémentaires, a plus d'intérimaires, consomme plus d'énergie et déclare plus d'événements.

## 2. Ce qui vient d'AdventureWorks

| Donnée | Usage |
|---|---|
| 290 salariés, leur poste, service et équipe actuels | Population des feuilles de temps, des formations et des accidents. Les techniciens `Production Technician - WC10` à `WC60` sont rattachés à l'atelier correspondant. |
| Ateliers et zones (`Production.Location`) | Lieux des accidents, des audits et des relevés environnementaux. |
| Heures de gamme réelles (`WorkOrderRouting.ActualResourceHrs`) | Indice d'activité mensuel par atelier : heures du mois rapportées à la moyenne des 12 premiers mois, lissées sur 3 mois. Les ateliers 30, 40 et 45 ont trop peu de gammes renseignées : leur indice suit l'activité cumulée des ateliers 10, 20, 50 et 60. |
| Ordres de fabrication et rebuts réels (`WorkOrder.ScrappedQty`, `ScrapReason`) | Non-conformités de production, ferraille, signal qualité des retours clients. |
| Lignes de commande fournisseur rejetées (`PurchaseOrderDetail.RejectedQty`) | Non-conformités fournisseurs. |
| Lignes de commande client expédiées | Base des retours clients. |

L'activité de production réelle d'AdventureWorks triple environ entre 2022 et 2025 alors que l'effectif reste de 290 personnes : le générateur absorbe cette hausse par les heures supplémentaires et l'intérim, ce qui alimente l'histoire de la montée en charge.

## 3. Scénario de contexte

| Date | Événement | Effet modélisé |
|---|---|---|
| 1er sept. 2023 | Lancement du programme sécurité « Zero Harm » | Accidents réduits progressivement de 30 % sur 4 mois ; signalements de presqu'accidents et de situations dangereuses multipliés par environ 2,5 ; campagne de rattrapage des formations jusqu'au 15 décembre. |
| Juin 2024 | Montée en charge de la production (visible dans AdventureWorks) | Plus d'heures supplémentaires et d'intérim, d'où plus d'exposition et d'accidents ; discipline de recyclage des formations en léger recul. |
| 1er oct. 2024 | Passage à la peinture hydro sur la ligne Paint (WC40) | COV −25 % en octobre puis −45 % ; eau +15 % et déchets dangereux −30 % sur WC40 ; défauts de peinture en hausse sur les vélos expédiés jusqu'à mi-janvier 2025. |
| 18 nov. 2024 | Audit de certification ISO 14001 | Audits externes ISO 14001 sur tous les ateliers. |

## 4. Temps de travail et intérim

**Calendrier** : jours ouvrés du lundi au vendredi, hors jours fériés d'entreprise américains (Independence Day, Labor Day, Thanksgiving et son lendemain, Noël, Nouvel An, Memorial Day). Heures planifiées = jours ouvrés × 8 h.

**Heures supplémentaires** : part des heures planifiées = coefficient × (indice d'activité − 1) + 1 % ± 0,4 %, plafonnée à 16 %. Coefficient : 4,5 % en production, 3 % logistique, 2,5 % maintenance, 1,5 % qualité, 1 % support. Variation individuelle de ±40 %.

**Intérim** (ateliers de production et logistique) : part des heures = 11 % × (indice − 1,25) ± 1 %, plafonnée à 55 %, répartie par équipe au prorata des effectifs. Coût horaire facturé entre 27,5 et 31 USD.

**Absences**, simulées jour par jour pour chaque salarié :
- **Accident du travail** : jours ouvrés qui suivent l'accident, à hauteur de 5/7 des jours calendaires perdus.
- **Maladie** : probabilité quotidienne de début d'arrêt de 0,75 %, multipliée par la saison (×1,5 à 1,7 en hiver, ×0,7 en été), par 1,2 en équipe de nuit et par (1 + 3 × part d'heures supplémentaires). Durée géométrique (moyenne 2,5 jours), et 3 % d'arrêts longs de 15 à 44 jours.
- **Congés** : droits annuels de 80, 120 ou 160 h selon l'ancienneté (moins de 5 ans, 5 à 10 ans, plus de 10 ans), concentrés en juillet-août (31 %) et en décembre (9 %).
- **Autres** : 0,12 % des jours.

## 5. Formations sécurité

Chaque salarié doit détenir les formations de son atelier (voir `required_for` dans le catalogue). Les secouristes sont les superviseurs de production, un technicien par atelier et par équipe, le superviseur logistique et le superviseur maintenance.

| Période | Règle de renouvellement |
|---|---|
| Juin 2022 | 22 % des habilitations sont déjà échues ; 45 % d'entre elles sont rattrapées avant le programme, les autres pendant la campagne. |
| Avant le programme | 42 % des renouvellements en retard, de 1 à 199 jours. |
| Campagne (sept. à mi-déc. 2023) | Tout ce qui est échu ou arrive à échéance est rattrapé. |
| Après la campagne | 28 % de renouvellements en retard (38 % à partir de juin 2024), de 10 à 149 jours. |

Note de session : loi normale (moyenne 86, écart-type 7), échec en dessous de 70, nouvelle session 2 à 5 semaines plus tard.

## 6. Événements santé-sécurité

**Taux de référence d'accidents avec arrêt**, pour un million d'heures : WC10 formage 24, WC20 soudure 30, WC30 ébavurage 21, WC40 peinture 13, WC45 peinture spéciale 15, WC50 sous-assemblage 15, WC60 assemblage final 18, logistique 22, maintenance 26, qualité 6, support 1,2.

**Facteurs multiplicatifs** : équipe du soir ×1,1 et de nuit ×1,28 ; intérimaires ×1,9 ; fatigue (1 + 2,5 × part d'heures supplémentaires) ; chaleur ×1,2 de juin à août en soudure et peinture ; programme sécurité (section 3).

**Pyramide** : soins médicaux = 2,2 × le taux d'accidents avec arrêt, premiers soins = 6,5 ×. Les presqu'accidents (11 × avant le programme, 28 × après) et les situations dangereuses (7 ×, puis 16 ×) dépendent de la culture de signalement et non du programme de réduction des accidents ; les intérimaires en déclarent moins (×0,6 et ×0,5).

**Tirage** : les événements fréquents (premiers soins, presqu'accidents, situations dangereuses) suivent une loi de Poisson par mois, atelier, équipe et type de travailleur. Les événements rares (accidents avec arrêt, soins médicaux) ne sont que quelques dizaines sur 3 ans : leur nombre mensuel est tiré par échantillonnage systématique de l'espérance cumulée, ce qui conserve le total et la tendance attendus sans bruit excessif, puis chaque événement est affecté à une cellule au prorata de son intensité.

**Victime** : tirée parmi les salariés de l'atelier et de l'équipe, avec un poids de 1,6 pour ceux dont une habilitation clé était échue le jour de l'accident (par exemple la formation soudure en WC20, la manutention en assemblage).

**Attributs** : nature de lésion selon l'atelier (brûlures en soudure, expositions chimiques en peinture, troubles musculosquelettiques en assemblage…), siège de lésion selon la nature, activité tirée parmi celles de l'atelier. Jours perdus : loi log-normale selon la nature (médiane de 4 jours pour une lésion oculaire à 49 jours pour une fracture), entre 1 et 180 jours. Délai de déclaration de 12 minutes à 30 heures pour une blessure, jusqu'à 4 jours pour un presqu'accident. Analyse clôturée en 10 à 59 jours pour un accident avec arrêt, 2 à 34 jours sinon ; les dossiers non clôturés au 31 mai 2025 restent ouverts.

## 7. Qualité

**Audits** : 5S chaque mois dans les 7 ateliers et en logistique ; ISO 9001 internes en mars et septembre ; ISO 14001 internes en mai (et septembre 2024, avant la certification) ; ISO 9001 externe chaque novembre. Score = base de l'atelier (70 à 80) + jusqu'à 6 points d'amélioration sur les 8 mois suivant le lancement du programme − jusqu'à 5 points quand l'activité dépasse 1,8 fois son niveau initial ± 4,5. Les écarts majeurs et mineurs suivent une loi de Poisson proportionnelle à l'écart au score parfait.

**Non-conformités** :
- *Production* : chaque ordre de fabrication réel avec au moins 5 pièces rebutées (Majeure à partir de 50, Critique à partir de 200). Coût = pièces rebutées × coût standard. L'atelier est déduit du motif de rebut (par exemple « Paint process failed » → WC40).
- *Fournisseurs* : chaque ligne de commande réellement rejetée à réception dans la fenêtre (Majeure si au moins 30 % de la ligne ou 500 pièces). Coût estimé = 15 % de la valeur rejetée (tri, retours, relances).
- *Audits* : chaque écart majeur ; 35 % des écarts mineurs.
- *Clients* : 30 % des retours pour défaut qualité.

Délai de clôture : 5 à 29 jours (mineure), 15 à 59 jours (majeure), 20 à 89 jours (critique), allongé de 0 à 39 jours pour les audits internes avant le programme.

**Retours clients** : probabilité de retour par ligne expédiée de 0,75 % pour les vélos, 0,5 % pour les composants, 1,5 % pour les vêtements, 0,6 % pour les accessoires. Pour les produits fabriqués, multipliée par (1 + 12 × taux de rebut réel du produit sur les 3 derniers mois). Vélos expédiés entre le 1er octobre 2024 et le 14 janvier 2025 : ×1,35, et poids du motif « Paint defect » ×2,6. Retour reçu 2 à 120 jours après l'expédition. Remboursement nul en cas de réparation ou d'échange ; coût de traitement d'environ 35 USD par vélo et 8 USD pour les autres articles.

## 8. Environnement

Valeur mensuelle = valeur de référence de la zone (à activité initiale) ajustée par l'indice d'activité, puis bruit de ±3,5 % :
- **Électricité** : 45 % fixes, 55 % proportionnels à l'activité.
- **Gaz** (fours de peinture) : 50 % fixes, 50 % proportionnels, plus jusqu'à 35 % de chauffage en hiver.
- **COV, eau, déchets** : proportionnels à l'activité ; la ferraille intègre 2,5 kg par pièce réellement rebutée dans l'atelier concerné.
- **Recyclage** : 95 % de la ferraille, 72 % des emballages, 18 % des déchets courants, 10 % des déchets dangereux.
- **Site** : éclairage et climatisation (pic en juillet-août), chauffage au gaz (pic en hiver), eau sanitaire de 0,55 m³ par personne présente (salariés et intérimaires), déchets courants.

## 9. Limites connues

- Effectif constant : AdventureWorks ne contient ni départ ni recrutement sur la période. Le turnover n'est donc pas analysable.
- Les volumes de production réels d'AdventureWorks triplent en 3 ans : c'est une donnée source, conservée telle quelle.
- Les accidents avec arrêt sont peu nombreux (une trentaine sur 3 ans) : un indicateur mensuel par atelier sera très volatil, privilégier les cumuls glissants sur 12 mois.
- Le taux de gravité est faible par rapport aux références françaises, car les durées d'arrêt suivent des ordres de grandeur américains.
- Tout est fictif : à présenter comme tel dans un portfolio.

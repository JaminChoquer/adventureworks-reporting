"""
Générateur des données complémentaires à AdventureWorks (santé-sécurité, formations, qualité, environnement, temps de travail).

Toutes les données produites sont fictives mais rattachées aux référentiels réels
d'AdventureWorks (salariés, équipes, ateliers, ordres de fabrication, commandes
clients et fournisseurs, produits). Les règles de génération sont documentées
dans docs/regles_generation.md. Le générateur est déterministe (graine fixe).

Fenêtre : juin 2022 à mai 2025 (36 mois complets de production AdventureWorks).
"""
import os, re, math
from datetime import date, datetime, timedelta, time
import numpy as np
import pandas as pd
import aw_loader as aw

SEED = 20251009
rng = np.random.default_rng(SEED)
START, END = date(2022, 6, 1), date(2025, 5, 31)
OUT = os.environ.get('OUT_DIR', './data/raw')
MONTHS = pd.period_range('2022-06', '2025-05', freq='M')

# --------------------------------------------------------------------------- #
# 0. Événements de scénario (contexte métier fictif, documenté et exporté)
# --------------------------------------------------------------------------- #
PROGRAM_LAUNCH = date(2023, 9, 1)      # programme sécurité « Zero Harm »
PROGRAM_CAMPAIGN_END = date(2023, 12, 15)
WATER_PAINT = date(2024, 10, 1)        # peinture hydro sur la ligne Paint (WC40)
ISO14001_CERT = date(2024, 11, 18)     # audit de certification ISO 14001

EVENTS = [
    (date(2023, 9, 1), 'Site', 'Safety program launch',
     'Launch of the "Zero Harm" safety program: refresher training campaign until mid-December, near-miss reporting app, monthly safety walks by supervisors.'),
    (date(2023, 12, 15), 'Site', 'Training campaign completed',
     'All overdue safety trainings caught up; renewals scheduled before expiry from now on.'),
    (date(2024, 6, 1), 'Production', 'Production ramp-up',
     'Order intake jumps (visible in AdventureWorks work orders). Overtime and temporary workers increase in every work center.'),
    (date(2024, 10, 1), 'WC40 Paint', 'Switch to water-based paint',
     'Solvent-based paint replaced by water-based paint on the main paint line. Lower VOC emissions; teething problems on finish quality for about three months.'),
    (date(2024, 11, 18), 'Site', 'ISO 14001 certification audit',
     'Initial ISO 14001 certification audit by an external body.'),
]

# --------------------------------------------------------------------------- #
# 1. Référentiels AdventureWorks
# --------------------------------------------------------------------------- #
E = aw.load('Employee')
H = aw.load('EmployeeDepartmentHistory')
H = H[H.EndDate.isna()][['BusinessEntityID', 'DepartmentID', 'ShiftID']]
E = E.merge(H, on='BusinessEntityID', how='left')
E['BusinessEntityID'] = E.BusinessEntityID.astype(int)
E['DepartmentID'] = E.DepartmentID.astype(int)
E['ShiftID'] = E.ShiftID.astype(int)
E['HireDate'] = pd.to_datetime(E.HireDate).dt.date
E['wc'] = E.JobTitle.str.extract(r'WC(\d+)')[0].astype(float)

def group_of(r):
    if not math.isnan(r.wc):
        return 'WC%d' % int(r.wc)
    if r.DepartmentID == 15:
        return 'LOG'
    if r.DepartmentID == 14:
        return 'MNT'
    if r.DepartmentID in (12, 13):
        return 'QA'
    return 'OFF'
E['grp'] = E.apply(group_of, axis=1)
E['is_tech'] = E.JobTitle.str.startswith('Production Technician')

WCS = ['WC10', 'WC20', 'WC30', 'WC40', 'WC45', 'WC50', 'WC60']
GROUPS = WCS + ['LOG', 'MNT', 'QA', 'OFF']
WC_LOC = {'WC10': 10, 'WC20': 20, 'WC30': 30, 'WC40': 40, 'WC45': 45, 'WC50': 50, 'WC60': 60}
LOG_LOCS = [7, 7, 7, 5, 2, 6, 4]          # zones logistiques, stock produits finis majoritaire
MNT_LOCS = [1, 1, 10, 20, 30, 40, 45, 50, 60]

L = aw.load('Location'); L['LocationID'] = L.LocationID.astype(int)
WO = aw.load('WorkOrder')
for c in ['WorkOrderID', 'ProductID', 'OrderQty', 'ScrappedQty']:
    WO[c] = WO[c].astype(int)
WO['StartDate'] = pd.to_datetime(WO.StartDate).dt.date
WOR = aw.load('WorkOrderRouting')
WOR['LocationID'] = WOR.LocationID.astype(int)
WOR['h'] = WOR.ActualResourceHrs.astype(float)
WOR['m'] = pd.to_datetime(WOR.ActualStartDate).dt.to_period('M')
P = aw.load('Product')
P['ProductID'] = P.ProductID.astype(int)
P['StandardCost'] = P.StandardCost.astype(float)
PS = aw.load('ProductSubcategory'); PC = aw.load('ProductCategory')
P = P.merge(PS[['ProductSubcategoryID', 'ProductCategoryID']], on='ProductSubcategoryID', how='left') \
     .merge(PC[['ProductCategoryID', 'Name']].rename(columns={'Name': 'Category'}), on='ProductCategoryID', how='left')
P['Category'] = P.Category.fillna('Component part')

# --------------------------------------------------------------------------- #
# 2. Calendrier et indices d'activité
# --------------------------------------------------------------------------- #
HOLIDAYS = {date(2022, 7, 4), date(2022, 9, 5), date(2022, 11, 24), date(2022, 11, 25), date(2022, 12, 26),
            date(2023, 1, 2), date(2023, 5, 29), date(2023, 7, 4), date(2023, 9, 4), date(2023, 11, 23),
            date(2023, 11, 24), date(2023, 12, 25), date(2024, 1, 1), date(2024, 5, 27), date(2024, 7, 4),
            date(2024, 9, 2), date(2024, 11, 28), date(2024, 11, 29), date(2024, 12, 25), date(2025, 1, 1),
            date(2025, 5, 26)}
DAYS = [START + timedelta(d) for d in range((END - START).days + 1)]
WORKDAYS = [d for d in DAYS if d.weekday() < 5 and d not in HOLIDAYS]
WD_BY_M = {m: [d for d in WORKDAYS if pd.Period(d, 'M') == m] for m in MONTHS}
SHIFT_HOURS = {1: (7, 15), 2: (15, 23), 3: (23, 7)}

# Indice d'activité par atelier : heures de gamme réelles (WorkOrderRouting) rapportées
# à la moyenne des 12 premiers mois, lissées sur 3 mois.
idx = {}
piv = WOR[WOR.m.isin(MONTHS)].pivot_table(index='m', columns='LocationID', values='h', aggfunc='sum').reindex(MONTHS)
# Les ateliers 30, 40 et 45 n'ont que quelques gammes renseignées dans AdventureWorks :
# leur indice suit l'activité globale plutôt que leur propre volume, trop bruité.
tot = piv[[10, 20, 50, 60]].sum(axis=1).rolling(3, min_periods=1, center=True).mean()
common = (tot / tot.iloc[:12].mean()).to_dict()
for wc, loc in WC_LOC.items():
    if loc in (30, 40, 45):
        idx[wc] = dict(common)
        continue
    s = piv[loc].rolling(3, min_periods=1, center=True).mean()
    idx[wc] = (s / s.iloc[:12].mean()).to_dict()
prod_idx = {m: float(np.mean([idx[w][m] for w in WCS])) for m in MONTHS}
for g in ['LOG', 'MNT', 'QA', 'OFF']:
    k = {'LOG': 0.6, 'MNT': 0.4, 'QA': 0.3, 'OFF': 0.1}[g]
    idx[g] = {m: 1 + k * (prod_idx[m] - 1) for m in MONTHS}

def ot_ratio(g, m):
    """Part d'heures supplémentaires selon la charge de l'atelier."""
    base = {'LOG': 0.03, 'MNT': 0.025, 'QA': 0.015, 'OFF': 0.01}.get(g, 0.045)
    return float(np.clip(base * (idx[g][m] - 1) + 0.01 + rng.normal(0, 0.004), 0, 0.16))
OT = {(g, m): ot_ratio(g, m) for g in GROUPS for m in MONTHS}

# --------------------------------------------------------------------------- #
# 3. Formations sécurité
# --------------------------------------------------------------------------- #
CATALOG = pd.DataFrame([
    ('GEN-IND', 'General safety induction', 'General', 4, 36, 'ALL'),
    ('FIRE', 'Fire safety and evacuation', 'General', 2, 24, 'ALL'),
    ('PPE', 'PPE and hearing conservation', 'General', 2, 12, 'WC10;WC20;WC30;WC40;WC45;WC50;WC60;MNT'),
    ('LOTO', 'Lockout / Tagout', 'Machinery', 4, 12, 'WC10;WC20;WC30;MNT'),
    ('MACH', 'Machine guarding and press safety', 'Machinery', 4, 24, 'WC10;WC30'),
    ('WELD', 'Welding and hot work safety', 'Hot work', 6, 24, 'WC20;MNT'),
    ('CHEM', 'Chemical and paint handling (HazCom)', 'Chemicals', 4, 12, 'WC40;WC45;LOG'),
    ('ERGO', 'Ergonomics and manual handling', 'Ergonomics', 3, 24, 'WC50;WC60;LOG'),
    ('FORK', 'Powered industrial truck (forklift)', 'Logistics', 8, 36, 'LOG'),
    ('FAID', 'First aid and CPR', 'Emergency', 8, 24, 'VOLUNTEERS'),
], columns=['course_code', 'course_title', 'category', 'duration_hours', 'validity_months', 'required_for'])
KEY_COURSES = {'WC10': ['MACH', 'LOTO'], 'WC20': ['WELD', 'LOTO'], 'WC30': ['MACH', 'LOTO'], 'WC40': ['CHEM'],
               'WC45': ['CHEM'], 'WC50': ['ERGO'], 'WC60': ['ERGO'], 'LOG': ['FORK', 'ERGO'], 'MNT': ['LOTO']}

# Secouristes : superviseurs de production + un technicien par atelier et par équipe
volunteers = set(E[E.JobTitle.str.startswith('Production Supervisor')].BusinessEntityID)
for (g, s), grp in E[E.is_tech].groupby(['grp', 'ShiftID']):
    volunteers.add(int(grp.sample(1, random_state=int(rng.integers(1e9))).BusinessEntityID.iloc[0]))
volunteers |= {121, 228}

def required_courses(r):
    out = []
    for _, c in CATALOG.iterrows():
        req = c.required_for
        if req == 'ALL' or (req == 'VOLUNTEERS' and r.BusinessEntityID in volunteers) or r.grp in req.split(';'):
            out.append(c.course_code)
    return out

def add_months(d, n):
    y, m = divmod(d.month - 1 + n, 12)
    return date(d.year + y, m + 1, min(d.day, 28))

TRAINERS = {'GEN-IND': 'Internal EHS', 'FIRE': 'Internal EHS', 'PPE': 'Internal EHS', 'LOTO': 'Internal EHS',
            'MACH': 'Internal EHS', 'WELD': 'Puget Welding Institute', 'CHEM': 'Internal EHS',
            'ERGO': 'Cascade Ergonomics', 'FORK': 'Northwest Lift Training', 'FAID': 'Red Cross chapter'}
train_rows, tid = [], 0
VALID = dict(zip(CATALOG.course_code, CATALOG.validity_months))
DUR = dict(zip(CATALOG.course_code, CATALOG.duration_hours))

def session_date(d):
    """Ramène une date sur un jour ouvré (sessions groupées en milieu de semaine)."""
    while d.weekday() >= 5 or d in HOLIDAYS:
        d += timedelta(1)
    return d

def campaign_day():
    return session_date(PROGRAM_LAUNCH + timedelta(int(rng.integers(3, (PROGRAM_CAMPAIGN_END - PROGRAM_LAUNCH).days))))

def next_session(expiry):
    """Date de renouvellement selon la période (avant, pendant, après le programme)."""
    if expiry < PROGRAM_LAUNCH:
        late = rng.random() < 0.42
        nxt = expiry + timedelta(int(rng.integers(1, 200)) if late else -int(rng.integers(1, 35)))
        return campaign_day() if nxt >= PROGRAM_LAUNCH else session_date(nxt)
    if expiry < PROGRAM_CAMPAIGN_END:
        return min(session_date(expiry - timedelta(int(rng.integers(1, 30)))), campaign_day())
    # Après le programme, renouvellements majoritairement à l'heure ; la montée en charge
    # de juin 2024 dégrade un peu la discipline (planning de production saturé).
    late = rng.random() < (0.38 if expiry >= date(2024, 6, 1) else 0.28)
    return session_date(expiry + timedelta(int(rng.integers(10, 150)) if late else -int(rng.integers(1, 35))))

def record(e, c, d):
    """Ajoute une session ; un échec entraîne une nouvelle session 2 à 5 semaines plus tard."""
    global tid
    v = VALID[c]
    score = int(np.clip(rng.normal(86, 7), 55, 100))
    tid += 1
    if score < 70:
        train_rows.append(dict(training_record_id='TR-%06d' % tid, business_entity_id=e, course_code=c,
                               completed_on=d, duration_hours=DUR[c], score=score, result='Fail',
                               provider=TRAINERS[c], valid_until=None))
        d = session_date(d + timedelta(int(rng.integers(14, 35))))
        score = int(np.clip(rng.normal(84, 6), 70, 100))
        tid += 1
    train_rows.append(dict(training_record_id='TR-%06d' % tid, business_entity_id=e, course_code=c,
                           completed_on=d, duration_hours=DUR[c], score=score, result='Pass',
                           provider=TRAINERS[c], valid_until=add_months(d, v)))
    return d

for _, r in E.iterrows():
    for c in required_courses(r):
        v = VALID[c]
        if rng.random() < 0.22:
            # Habilitation déjà échue en juin 2022 : rattrapage avant ou pendant le programme
            last = session_date(START - timedelta(int(rng.integers(30 * v + 5, 30 * v + 240))))
            record(r.BusinessEntityID, c, last)
            d = session_date(START + timedelta(int(rng.integers(20, (PROGRAM_LAUNCH - START).days)))) if rng.random() < 0.45 else campaign_day()
        else:
            last = session_date(START - timedelta(int(rng.integers(5, 30 * v - 5))))
            d = record(r.BusinessEntityID, c, last)
            d = next_session(add_months(d, v))
        while d <= END:
            d = record(r.BusinessEntityID, c, d)
            d = next_session(add_months(d, v))
TR = pd.DataFrame(train_rows)
TR_pass = TR[TR.result == 'Pass']
valid_spans = {}
for (e, c), g in TR_pass.groupby(['business_entity_id', 'course_code']):
    valid_spans[(e, c)] = sorted(zip(g.completed_on, g.valid_until))

def trained_ok(e, c, d):
    for a, b in valid_spans.get((e, c), []):
        if a <= d <= b:
            return True
    return False

# --------------------------------------------------------------------------- #
# 4. Intérim par atelier et par équipe
# --------------------------------------------------------------------------- #
AGENCIES = ['Northwest Staffing', 'Cascade Workforce', 'Evergreen Temps']
staff = E.groupby(['grp', 'ShiftID']).size()
temp_rows = []
for m in MONTHS:
    bd = len(WD_BY_M[m])
    for g in WCS + ['LOG']:
        share = float(np.clip(0.11 * (idx[g][m] - 1.25) + rng.normal(0, 0.01), 0, 0.55))
        if share <= 0.005:
            continue
        for s in (1, 2, 3):
            n = staff.get((g, s), 0)
            if n == 0:
                continue
            hours = n * bd * 8 * share
            if hours < 40:
                continue
            temp_rows.append(dict(month=str(m), work_center=g, shift_id=s,
                                  agency=AGENCIES[int(rng.integers(0, 3))] if g != 'LOG' else 'Northwest Staffing',
                                  temp_fte=round(hours / (bd * 8), 2), temp_hours=round(hours, 1),
                                  cost_usd=round(hours * rng.uniform(27.5, 31.0), 2)))
TEMP = pd.DataFrame(temp_rows)

# --------------------------------------------------------------------------- #
# 5. Événements EHS (accidents, soins, presqu'accidents, situations dangereuses)
# --------------------------------------------------------------------------- #
# Taux de base d'accidents avec arrêt (LTI) pour 1 million d'heures, par atelier
LTI_RATE = {'WC10': 24, 'WC20': 30, 'WC30': 21, 'WC40': 13, 'WC45': 15, 'WC50': 15, 'WC60': 18,
            'LOG': 22, 'MNT': 26, 'QA': 6, 'OFF': 1.2}
# Pyramide des événements (multiplicateurs du taux LTI)
PYR = {'Medical treatment': 2.2, 'First aid': 6.5}
NEAR_MISS = {'before': 11, 'after': 28}
HAZARD = {'before': 7, 'after': 16}
SHIFT_MULT = {1: 1.0, 2: 1.1, 3: 1.28}

NATURE = {
    'WC10': {'Laceration': .30, 'Crush / pinch': .24, 'Contusion': .14, 'Musculoskeletal disorder': .14, 'Eye injury': .08, 'Fracture': .05, 'Sprain / strain': .05},
    'WC20': {'Burn': .40, 'Eye injury': .18, 'Laceration': .14, 'Musculoskeletal disorder': .10, 'Chemical exposure': .08, 'Contusion': .10},
    'WC30': {'Laceration': .30, 'Eye injury': .24, 'Musculoskeletal disorder': .18, 'Contusion': .14, 'Burn': .06, 'Sprain / strain': .08},
    'WC40': {'Chemical exposure': .34, 'Musculoskeletal disorder': .20, 'Eye injury': .14, 'Contusion': .12, 'Sprain / strain': .12, 'Burn': .08},
    'WC45': {'Chemical exposure': .36, 'Musculoskeletal disorder': .18, 'Eye injury': .16, 'Contusion': .12, 'Sprain / strain': .10, 'Laceration': .08},
    'WC50': {'Musculoskeletal disorder': .38, 'Laceration': .20, 'Crush / pinch': .16, 'Contusion': .14, 'Sprain / strain': .12},
    'WC60': {'Musculoskeletal disorder': .40, 'Sprain / strain': .16, 'Contusion': .16, 'Laceration': .14, 'Crush / pinch': .14},
    'LOG': {'Contusion': .26, 'Sprain / strain': .22, 'Musculoskeletal disorder': .22, 'Fracture': .10, 'Crush / pinch': .12, 'Laceration': .08},
    'MNT': {'Laceration': .22, 'Contusion': .18, 'Burn': .12, 'Crush / pinch': .14, 'Sprain / strain': .14, 'Fracture': .08, 'Eye injury': .12},
    'QA': {'Contusion': .30, 'Laceration': .25, 'Sprain / strain': .25, 'Eye injury': .20},
    'OFF': {'Sprain / strain': .40, 'Contusion': .35, 'Musculoskeletal disorder': .25},
}
BODY = {'Laceration': {'Hand / finger': .7, 'Forearm': .2, 'Leg': .1},
        'Crush / pinch': {'Hand / finger': .75, 'Foot / toe': .25},
        'Burn': {'Hand / finger': .45, 'Forearm': .35, 'Face / neck': .2},
        'Musculoskeletal disorder': {'Back': .45, 'Shoulder': .35, 'Wrist': .2},
        'Contusion': {'Leg': .35, 'Hand / finger': .25, 'Head': .15, 'Torso': .25},
        'Eye injury': {'Eye': 1.0},
        'Fracture': {'Hand / finger': .4, 'Foot / toe': .35, 'Wrist': .25},
        'Chemical exposure': {'Respiratory system': .55, 'Skin': .3, 'Eye': .15},
        'Sprain / strain': {'Ankle': .45, 'Knee': .25, 'Wrist': .3}}
ACTIVITY = {'WC10': ['Tube bending', 'Press operation', 'Thermoforming', 'Material handling'],
            'WC20': ['Robotic welding cell', 'Manual TIG welding', 'Weld grinding', 'Jig changeover'],
            'WC30': ['Deburring', 'Polishing', 'Abrasive blasting'],
            'WC40': ['Spray painting', 'Pretreatment line', 'Masking', 'Paint mixing'],
            'WC45': ['Custom painting', 'Paint mixing', 'Decal application'],
            'WC50': ['Wheel assembly', 'Drivetrain subassembly', 'Brake subassembly'],
            'WC60': ['Final bike assembly', 'Packing', 'Pallet handling'],
            'LOG': ['Forklift operation', 'Manual handling', 'Racking', 'Truck loading'],
            'MNT': ['Machine repair', 'Electrical work', 'Preventive maintenance', 'Cleaning'],
            'QA': ['Inspection', 'Laboratory testing'], 'OFF': ['Office work', 'Walking on site']}
ROOT = ['Human factor', 'Equipment', 'Method', 'Work environment', 'Organization']
ROOT_W = {'before': [.34, .20, .20, .14, .12], 'after': [.26, .24, .22, .14, .14]}
NM_TEXT = {
    'WC10': ['Press guard found bypassed', 'Tube fell from bending machine', 'Operator hand close to press die', 'Sharp offcuts left on floor'],
    'WC20': ['Welding curtain torn at robotic cell', 'Gas cylinder not secured', 'Spark ignited cardboard near cell', 'Light curtain fault on robot cell'],
    'WC30': ['Grinding disc cracked during use', 'Missing face shield at polishing station', 'Dust extraction stopped'],
    'WC40': ['Paint booth extraction failure', 'Solvent spill near mixing room', 'Respirator cartridges expired', 'Hanger fell from conveyor'],
    'WC45': ['Unlabeled paint container', 'Spray gun hose leaking', 'Booth door left open during spraying'],
    'WC50': ['Wheel truing stand unstable', 'Torque tool cable worn', 'Box of parts fell from shelf'],
    'WC60': ['Bike frame slipped from assembly stand', 'Pallet wrap knife left on table', 'Heavy carton lifted without help'],
    'LOG': ['Forklift near-collision with pedestrian', 'Pallet overhanging rack beam', 'Blocked emergency exit in warehouse', 'Load fell from forklift forks'],
    'MNT': ['Machine restarted during maintenance', 'Ladder with damaged rung', 'Live cable exposed in panel'],
    'QA': ['Test bench guard missing', 'Wet floor in lab'], 'OFF': ['Trailing cable in corridor', 'Wet floor at entrance'],
}
DAYS_LOST_MU = {'Musculoskeletal disorder': 3.6, 'Fracture': 3.9, 'Burn': 2.5, 'Laceration': 1.9, 'Crush / pinch': 2.4,
                'Contusion': 2.0, 'Eye injury': 1.4, 'Chemical exposure': 1.8, 'Sprain / strain': 2.6}

def pick(d):
    k = list(d); p = np.array(list(d.values()), float)
    return k[int(rng.choice(len(k), p=p / p.sum()))]

def loc_for(g):
    if g in WC_LOC:
        return WC_LOC[g]
    if g == 'LOG':
        return int(rng.choice(LOG_LOCS))
    if g == 'MNT':
        return int(rng.choice(MNT_LOCS))
    if g == 'QA':
        return int(rng.choice(list(WC_LOC.values())))
    return None

def occurred_time(day, shift):
    a, b = SHIFT_HOURS[shift]
    span = (b - a) % 24
    t = datetime.combine(day, time(a)) + timedelta(minutes=int(rng.integers(15, span * 60 - 10)))
    return t

def program_factor(d):
    """Effet progressif du programme sécurité sur les accidents (−30 % après 4 mois)."""
    if d < PROGRAM_LAUNCH:
        return 1.0
    k = min(1.0, (d - PROGRAM_LAUNCH).days / 120)
    return 1.0 - 0.30 * k

def heat_factor(g, m):
    return 1.2 if g in ('WC20', 'WC40', 'WC45') and m.month in (6, 7, 8) else 1.0

inc_rows = []
emp_by_cell = {k: v.BusinessEntityID.tolist() for k, v in E.groupby(['grp', 'ShiftID'])}
def make_event(m, g, s, wtype, emps, etype):
    bd_days = WD_BY_M[m]
    phase = 'after' if date(m.year, m.month, 15) >= PROGRAM_LAUNCH else 'before'
    day = bd_days[int(rng.integers(0, len(bd_days)))]
    occ = occurred_time(day, s)
    injury = etype in ('Lost time injury', 'Medical treatment', 'First aid')
    emp = None
    if wtype == 'Employee' and injury:
        # Les salariés dont une habilitation clé est échue sont surreprésentés
        w = np.array([1.6 if any(not trained_ok(e, c, day) for c in KEY_COURSES.get(g, [])) else 1.0 for e in emps])
        emp = int(rng.choice(emps, p=w / w.sum()))
    reporter = int(rng.choice(emps)) if (wtype == 'Employee' or not injury) else None
    nature = pick(NATURE[g]) if injury else None
    if etype == 'Lost time injury':
        dl = int(np.clip(round(rng.lognormal(DAYS_LOST_MU[nature], 0.9)), 1, 180))
        dr = int(rng.integers(0, 15))
        sev = 'High' if dl >= 30 else 'Medium'
    elif etype == 'Medical treatment':
        dl, dr = 0, int(rng.choice([0, 0, 0, 1, 2, 3, 5, 7, 10]))
        sev = 'Medium' if dr else 'Low'
    else:
        dl, dr = 0, 0
        sev = 'Low' if etype == 'First aid' else pick({'Low': .45, 'Medium': .35, 'High': .15, 'Critical': .05})
    rep_delay = timedelta(minutes=int(rng.integers(12, 1800))) if injury else timedelta(minutes=int(rng.integers(30, 5760)))
    inv_days = int(rng.integers(10, 60)) if etype == 'Lost time injury' else int(rng.integers(2, 35))
    closed = occ + rep_delay + timedelta(days=inv_days)
    status = 'Closed' if closed.date() <= END else ('Under investigation' if etype == 'Lost time injury' else 'Open')
    act = ACTIVITY[g][int(rng.integers(0, len(ACTIVITY[g])))]
    body = pick(BODY[nature]) if injury else None
    desc = (f'{nature} to {body.lower()} during {act.lower()}' if injury
            else NM_TEXT[g][int(rng.integers(0, len(NM_TEXT[g])))])
    inc_rows.append(dict(
        incident_id=None, event_type=etype, occurred_at=occ, reported_at=occ + rep_delay,
        location_id=loc_for(g), work_center=g, shift_id=s, worker_type=wtype,
        injured_business_entity_id=emp, reported_by_business_entity_id=reporter,
        injury_nature=nature, body_part=body, activity=act,
        root_cause_category=ROOT[int(rng.choice(5, p=ROOT_W[phase]))],
        severity_potential=sev, days_lost=dl, days_restricted=dr, description=desc,
        status=status, closed_at=closed if status == 'Closed' else None))


# Exposition et intensités attendues par cellule (mois × atelier × équipe × type de travailleur)
cells = []
for m in MONTHS:
    bd_days = WD_BY_M[m]
    mid = date(m.year, m.month, 15)
    phase = 'after' if mid >= PROGRAM_LAUNCH else 'before'
    for (g, s), emps in emp_by_cell.items():
        ot = OT[(g, m)]
        emp_hours = len(emps) * len(bd_days) * 8 * (1 + ot)
        trow = TEMP[(TEMP.month == str(m)) & (TEMP.work_center == g) & (TEMP.shift_id == s)]
        temp_hours = float(trow.temp_hours.sum()) if len(trow) else 0.0
        base = LTI_RATE[g] / 1e6 * SHIFT_MULT[s] * heat_factor(g, m) * (1 + 2.5 * ot) * program_factor(mid)
        for wtype, hrs, mult in (('Employee', emp_hours, 1.0), ('Temporary', temp_hours, 1.9)):
            if hrs <= 0:
                continue
            lam_lti = base * mult * hrs
            rep = LTI_RATE[g] / 1e6 * SHIFT_MULT[s] * hrs   # les signalements suivent la culture sécurité
            cells.append(dict(m=m, g=g, s=s, wtype=wtype, emps=emps, lam={
                'Lost time injury': lam_lti,
                'Medical treatment': lam_lti * PYR['Medical treatment'],
                'First aid': lam_lti * PYR['First aid'],
                'Near miss': rep * NEAR_MISS[phase] * (0.6 if wtype == 'Temporary' else 1.0),
                'Hazardous situation': rep * HAZARD[phase] * (0.5 if wtype == 'Temporary' else 1.0)}))

# Événements fréquents : tirage de Poisson par cellule.
for c in cells:
    for etype in ('First aid', 'Near miss', 'Hazardous situation'):
        for _ in range(rng.poisson(c['lam'][etype])):
            make_event(c['m'], c['g'], c['s'], c['wtype'], c['emps'], etype)

# Événements rares (accidents avec arrêt, soins médicaux) : quelques dizaines sur 3 ans, où le
# bruit de Poisson masquerait toute tendance. On tire le nombre mensuel par échantillonnage
# systématique de l'espérance cumulée (total et tendance conservés, variance minimale),
# puis chaque événement est affecté à une cellule du mois au prorata de son intensité.
for etype in ('Lost time injury', 'Medical treatment'):
    u, cum_prev = rng.random(), 0.0
    for m in MONTHS:
        cm = [c for c in cells if c['m'] == m]
        lam = np.array([c['lam'][etype] for c in cm])
        cum = cum_prev + lam.sum()
        n = int(math.floor(cum + u) - math.floor(cum_prev + u))
        cum_prev = cum
        for _ in range(n):
            c = cm[int(rng.choice(len(cm), p=lam / lam.sum()))]
            make_event(m, c['g'], c['s'], c['wtype'], c['emps'], etype)

INC = pd.DataFrame(inc_rows).sort_values('occurred_at').reset_index(drop=True)
INC['incident_id'] = INC.groupby(INC.occurred_at.dt.year).cumcount().add(1).astype(str).str.zfill(4).radd(INC.occurred_at.dt.year.astype(str) + '-').radd('EHS-')

# --------------------------------------------------------------------------- #
# 6. Temps de travail et absences par salarié et par mois
# --------------------------------------------------------------------------- #
VAC_W = {1: .06, 2: .05, 3: .08, 4: .07, 5: .07, 6: .10, 7: .16, 8: .15, 9: .06, 10: .05, 11: .06, 12: .09}
SEAS_SICK = {12: 1.6, 1: 1.7, 2: 1.5, 3: 1.2, 6: .75, 7: .7, 8: .7}
wd_index = {d: i for i, d in enumerate(WORKDAYS)}
lti = INC[(INC.event_type == 'Lost time injury') & INC.injured_business_entity_id.notna()]
ts_rows = []
for _, r in E.iterrows():
    e, g, s = r.BusinessEntityID, r.grp, r.ShiftID
    status = np.array([''] * len(WORKDAYS), dtype=object)
    # Arrêts accident du travail (jours ouvrés suivant l'accident)
    for _, a in lti[lti.injured_business_entity_id == e].iterrows():
        d0 = a.occurred_at.date() + timedelta(1)
        k = next((wd_index[d] for d in WORKDAYS if d >= d0), None)
        if k is None:
            continue
        n_wd = int(round(a.days_lost * 5 / 7)) or 1
        status[k:k + n_wd] = np.where(status[k:k + n_wd] == '', 'accident', status[k:k + n_wd])
    tenure = (START - r.HireDate).days / 365
    annual_vac = 80 if tenure < 5 else (120 if tenure < 10 else 160)
    for i, d in enumerate(WORKDAYS):
        if status[i]:
            continue
        m = d.month
        ot_here = OT[(g, pd.Period(d, 'M'))]
        p_sick = 0.0075 * SEAS_SICK.get(m, 1.0) * (1.2 if s == 3 else 1.0) * (1 + 3 * ot_here)
        if rng.random() < p_sick:
            n = int(rng.geometric(0.4)) if rng.random() > 0.03 else int(rng.integers(15, 45))
            sl = slice(i, min(i + n, len(WORKDAYS)))
            status[sl] = np.where(status[sl] == '', 'sick', status[sl])
            continue
        if rng.random() < annual_vac / 8 / 250 * VAC_W[m] * 12:
            n = int(rng.choice([1, 1, 2, 3, 5]))
            sl = slice(i, min(i + n, len(WORKDAYS)))
            status[sl] = np.where(status[sl] == '', 'vacation', status[sl])
            continue
        if rng.random() < 0.0012:
            status[i] = 'other'
    for m in MONTHS:
        ids = [wd_index[d] for d in WD_BY_M[m]]
        st = status[ids]
        sched = len(ids) * 8.0
        ot = round(sched * OT[(g, m)] * rng.uniform(0.6, 1.4), 1) if g != 'OFF' or rng.random() < 0.15 else 0.0
        ab = {k: float((st == k).sum() * 8) for k in ('sick', 'accident', 'vacation', 'other')}
        worked = max(0.0, sched + ot - sum(ab.values()))
        if sum(ab.values()) >= sched:
            ot = 0.0
            worked = 0.0
        ts_rows.append(dict(month=str(m), business_entity_id=e, department_id=r.DepartmentID, shift_id=s,
                            work_center=g, scheduled_hours=sched, overtime_hours=ot,
                            absence_sickness_hours=ab['sick'], absence_work_accident_hours=ab['accident'],
                            absence_vacation_hours=ab['vacation'], absence_other_hours=ab['other'],
                            worked_hours=round(worked, 1)))
TS = pd.DataFrame(ts_rows)

# --------------------------------------------------------------------------- #
# 7. Qualité : audits, retours clients, non-conformités
# --------------------------------------------------------------------------- #
QA_STAFF = [211, 212, 213, 214, 215, 216]
aud_rows, ano = [], 0
AUD_BASE = {'WC10': 74, 'WC20': 71, 'WC30': 70, 'WC40': 77, 'WC45': 79, 'WC50': 80, 'WC60': 78, 'LOG': 72}
def audit_score(g, d, base_shift=0):
    trend = 6 * min(1, max(0, (d - PROGRAM_LAUNCH).days) / 240)
    load = -max(0.0, min(5.0, 2.0 * (prod_idx[pd.Period(d, 'M')] - 1.8)))
    return float(np.clip(AUD_BASE[g] + base_shift + trend + load + rng.normal(0, 4.5), 40, 99))

def add_audit(d, g, atype, auditor, shift=0, external=False):
    global ano
    sc = audit_score(g, d, shift)
    deficit = (100 - sc) / 100
    major = int(rng.poisson(deficit * (2.2 if atype != '5S' else 0.9)))
    minor = int(rng.poisson(deficit * (9 if atype != '5S' else 6)))
    obs = int(rng.poisson(2 + deficit * 4))
    ano += 1
    aud_rows.append(dict(audit_id='AUD-%05d' % ano, audit_date=d, audit_type=atype,
                         location_id=WC_LOC.get(g, 7), work_center=g,
                         auditor_business_entity_id=None if external else auditor,
                         auditor_organization='External certification body' if external else 'Internal QA',
                         score=round(sc, 1), findings_major=major, findings_minor=minor, observations=obs))

for m in MONTHS:
    wds = WD_BY_M[m]
    for g in list(AUD_BASE):
        add_audit(wds[int(rng.integers(0, len(wds)))], g, '5S', int(rng.choice(QA_STAFF)))
    if m.month in (3, 9):
        for g in WCS:
            add_audit(wds[int(rng.integers(0, len(wds)))], g, 'ISO 9001 internal', int(rng.choice([211, 212])), -2)
    if m.month == 5 or (m.year == 2024 and m.month == 9):
        for g in WCS:
            add_audit(wds[int(rng.integers(0, len(wds)))], g, 'ISO 14001 internal', 212, -4)
    if m.month == 11:
        for g in WCS:
            add_audit(session_date(date(m.year, 11, 14)), g, 'ISO 9001 external', None, 2, external=True)
        if m.year == 2024:
            for g in WCS:
                add_audit(ISO14001_CERT, g, 'ISO 14001 external', None, 0, external=True)
AUD = pd.DataFrame(aud_rows)

# Retours clients
SOH = aw.load('SalesOrderHeader')
SOD = aw.load('SalesOrderDetail')
SOH['ShipDate'] = pd.to_datetime(SOH.ShipDate).dt.date
for c in ['SalesOrderID']:
    SOH[c] = SOH[c].astype(int); SOD[c] = SOD[c].astype(int)
SOD['ProductID'] = SOD.ProductID.astype(int); SOD['OrderQty'] = SOD.OrderQty.astype(int)
SOD['UnitPrice'] = SOD.UnitPrice.astype(float); SOD['UnitPriceDiscount'] = SOD.UnitPriceDiscount.astype(float)
SOD['SalesOrderDetailID'] = SOD.SalesOrderDetailID.astype(int)
X = SOD.merge(SOH[['SalesOrderID', 'ShipDate', 'OnlineOrderFlag']], on='SalesOrderID') \
       .merge(P[['ProductID', 'Category', 'MakeFlag', 'StandardCost']], on='ProductID')
X = X[(X.ShipDate >= START) & (X.ShipDate <= END)].copy()
# Taux de rebut par produit et par mois (signal qualité de production)
WO['m'] = pd.to_datetime(WO.StartDate).dt.to_period('M')
scr = WO.groupby(['ProductID', 'm']).agg(sc=('ScrappedQty', 'sum'), q=('OrderQty', 'sum'))
scr_rate = (scr.sc / scr.q).to_dict()
BASE_RET = {'Bikes': .0075, 'Components': .005, 'Clothing': .015, 'Accessories': .006, 'Component part': .004}
REASONS = {'Bikes': {'Paint defect': .24, 'Weld crack on frame': .12, 'Wheel misalignment': .18, 'Drivetrain noise': .14, 'Missing parts': .10, 'Damaged in transit': .16, 'Changed mind': .06},
           'Components': {'Defective part': .45, 'Wrong part shipped': .25, 'Damaged in transit': .2, 'Changed mind': .1},
           'Clothing': {'Wrong size': .55, 'Defective stitching': .2, 'Changed mind': .25},
           'Accessories': {'Defective item': .45, 'Damaged in transit': .3, 'Changed mind': .25},
           'Component part': {'Defective part': .7, 'Damaged in transit': .3}}
ORIGIN = {'Paint defect': 'WC40', 'Weld crack on frame': 'WC20', 'Wheel misalignment': 'WC50', 'Drivetrain noise': 'WC50',
          'Missing parts': 'WC60', 'Defective part': None, 'Wrong part shipped': 'LOG', 'Damaged in transit': 'LOG'}
ret_rows, rno = [], 0
for r in X.itertuples():
    m = pd.Period(r.ShipDate, 'M')
    p = BASE_RET.get(r.Category, .005)
    if r.MakeFlag == '1':
        sr = np.mean([scr_rate.get((r.ProductID, m - k), 0.0) for k in (0, 1, 2)])
        p *= 1 + 12 * sr
    if r.Category == 'Bikes' and WATER_PAINT <= r.ShipDate < date(2025, 1, 15):
        p *= 1.35
    if rng.random() >= p:
        continue
    reasons = dict(REASONS.get(r.Category, {'Defective part': 1}))
    if r.Category == 'Bikes' and WATER_PAINT <= r.ShipDate < date(2025, 1, 15):
        reasons['Paint defect'] *= 2.6
    reason = pick(reasons)
    rdate = r.ShipDate + timedelta(int(np.clip(rng.gamma(2.2, 9), 2, 120)))
    if rdate > END:
        continue
    qty = 1 if r.OrderQty == 1 or rng.random() < 0.8 else int(rng.integers(1, r.OrderQty + 1))
    disp = pick({'Repair': .35, 'Replace': .3, 'Credit': .2, 'Scrap': .15}) if reason != 'Changed mind' else 'Restock'
    if reason == 'Wrong size':
        disp = 'Exchange'
    rno += 1
    origin = ORIGIN.get(reason) if r.MakeFlag == '1' or reason in ('Wrong part shipped', 'Damaged in transit') else None
    ret_rows.append(dict(rma_id='RMA-%06d' % rno, return_date=rdate, sales_order_id=r.SalesOrderID,
                         sales_order_detail_id=r.SalesOrderDetailID, product_id=r.ProductID, qty_returned=qty,
                         return_reason=reason, defect_origin_work_center=origin, disposition=disp,
                         refund_amount_usd=round(qty * r.UnitPrice * (1 - r.UnitPriceDiscount) * (0 if disp in ('Repair', 'Exchange') else 1), 2),
                         handling_cost_usd=round(qty * (35 if r.Category == 'Bikes' else 8) * rng.uniform(.8, 1.3), 2)))
RET = pd.DataFrame(ret_rows)

# Non-conformités
SCRAP_WC = {1: 'WC50', 2: 'WC40', 3: 'WC30', 4: 'WC10', 5: 'WC10', 6: 'WC10', 7: 'WC60', 8: 'WC40', 9: 'WC40',
            10: 'WC50', 11: 'WC20', 12: 'WC10', 13: 'WC10', 14: 'WC10', 15: 'WC10', 16: 'WC50'}
nc_rows = []
def nc(detected, source, sev, **kw):
    lead = {'Minor': (5, 30), 'Major': (15, 60), 'Critical': (20, 90)}[sev]
    closed = detected + timedelta(int(rng.integers(*lead)))
    if source == 'Internal audit' and detected < PROGRAM_LAUNCH:
        closed += timedelta(int(rng.integers(0, 40)))
    row = dict(nc_id=None, detected_on=detected, source=source, severity=sev,
               status='Closed' if closed <= END else 'Open', closed_on=closed if closed <= END else None)
    row.update(kw)
    nc_rows.append(row)

wo = WO[(WO.StartDate >= START) & (WO.StartDate <= END) & (WO.ScrappedQty >= 5)].merge(P[['ProductID', 'StandardCost']], on='ProductID')
for r in wo.itertuples():
    sev = 'Critical' if r.ScrappedQty >= 200 else ('Major' if r.ScrappedQty >= 50 else 'Minor')
    rid = int(r.ScrapReasonID)
    nc(r.StartDate + timedelta(int(rng.integers(0, 4))), 'Production', sev, work_center=SCRAP_WC[rid],
       location_id=WC_LOC[SCRAP_WC[rid]], work_order_id=r.WorkOrderID, product_id=r.ProductID, scrap_reason_id=rid,
       qty_affected=r.ScrappedQty, estimated_cost_usd=round(r.ScrappedQty * r.StandardCost, 2),
       root_cause_category=pick({'Method': .3, 'Equipment': .3, 'Human factor': .25, 'Material': .15}))

POH = aw.load('PurchaseOrderHeader'); POD = aw.load('PurchaseOrderDetail')
POD = POD.merge(POH[['PurchaseOrderID', 'VendorID']], on='PurchaseOrderID')
POD['DueDate'] = pd.to_datetime(POD.DueDate).dt.date
POD['RejectedQty'] = POD.RejectedQty.astype(float); POD['ReceivedQty'] = POD.ReceivedQty.astype(float)
POD['UnitPrice'] = POD.UnitPrice.astype(float)
sup = POD[(POD.RejectedQty > 0) & (POD.DueDate >= START) & (POD.DueDate <= END)]
for r in sup.itertuples():
    share = r.RejectedQty / max(r.ReceivedQty, 1)
    sev = 'Major' if share >= 0.3 or r.RejectedQty >= 500 else 'Minor'
    nc(r.DueDate, 'Supplier', sev, location_id=pick({2: .4, 5: .3, 6: .3}), work_center='LOG',
       purchase_order_id=int(r.PurchaseOrderID), purchase_order_detail_id=int(r.PurchaseOrderDetailID),
       vendor_id=int(r.VendorID), product_id=int(r.ProductID), qty_affected=int(r.RejectedQty),
       estimated_cost_usd=round(r.RejectedQty * r.UnitPrice * 0.15, 2),
       root_cause_category=pick({'Material': .6, 'Method': .25, 'Organization': .15}))

for r in AUD.itertuples():
    for _ in range(r.findings_major):
        nc(r.audit_date, 'Internal audit' if r.auditor_organization == 'Internal QA' else 'External audit', 'Major',
           location_id=r.location_id, work_center=r.work_center, audit_id=r.audit_id,
           root_cause_category=pick({'Method': .35, 'Organization': .3, 'Human factor': .2, 'Work environment': .15}))
    for _ in range(r.findings_minor):
        if rng.random() < 0.35:
            nc(r.audit_date, 'Internal audit' if r.auditor_organization == 'Internal QA' else 'External audit', 'Minor',
               location_id=r.location_id, work_center=r.work_center, audit_id=r.audit_id,
               root_cause_category=pick({'Method': .35, 'Organization': .3, 'Human factor': .2, 'Work environment': .15}))

qual = RET[RET.return_reason.isin(['Paint defect', 'Weld crack on frame', 'Wheel misalignment', 'Drivetrain noise', 'Missing parts', 'Defective part', 'Defective stitching', 'Defective item'])]
for r in qual.itertuples():
    if rng.random() < 0.3:
        sev = 'Major' if r.return_reason in ('Weld crack on frame',) else 'Minor'
        wc = r.defect_origin_work_center
        nc(r.return_date + timedelta(int(rng.integers(1, 6))), 'Customer', sev, rma_id=r.rma_id,
           sales_order_id=r.sales_order_id, product_id=r.product_id, work_center=wc,
           location_id=WC_LOC.get(wc) if wc else None, qty_affected=r.qty_returned,
           estimated_cost_usd=round(r.refund_amount_usd + r.handling_cost_usd, 2),
           root_cause_category=pick({'Method': .3, 'Equipment': .25, 'Human factor': .25, 'Material': .2}))
NC = pd.DataFrame(nc_rows).sort_values('detected_on').reset_index(drop=True)
NC['nc_id'] = ['NC-%05d' % (i + 1) for i in range(len(NC))]
NC['description'] = NC.apply(lambda r: {
    'Production': 'Scrap above threshold on work order',
    'Supplier': 'Parts rejected at goods receipt',
    'Internal audit': 'Audit finding',
    'External audit': 'External audit finding',
    'Customer': 'Customer complaint after return'}[r.source], axis=1)

# --------------------------------------------------------------------------- #
# 8. Environnement : relevés mensuels par zone (format long)
# --------------------------------------------------------------------------- #
ENV_BASE = {  # valeur à indice d'activité 1
    10: dict(electricity_kwh=38000, waste_metal_kg=9000, waste_hazardous_kg=150),
    20: dict(electricity_kwh=52000, waste_metal_kg=3500, waste_hazardous_kg=90),
    30: dict(electricity_kwh=21000, waste_metal_kg=2500, waste_hazardous_kg=180),
    40: dict(electricity_kwh=34000, natural_gas_kwh=30000, water_m3=420, voc_kg=950, waste_hazardous_kg=600),
    45: dict(electricity_kwh=16000, natural_gas_kwh=15000, water_m3=120, voc_kg=380, waste_hazardous_kg=250),
    50: dict(electricity_kwh=12000, waste_general_kg=900),
    60: dict(electricity_kwh=14000, waste_packaging_kg=2500),
    1: dict(electricity_kwh=4000, waste_hazardous_kg=120),
    2: dict(electricity_kwh=6000), 4: dict(electricity_kwh=3000), 5: dict(electricity_kwh=6000),
    6: dict(electricity_kwh=6000), 7: dict(electricity_kwh=6500, waste_packaging_kg=800),
}
UNIT = {'electricity_kwh': 'kWh', 'natural_gas_kwh': 'kWh', 'water_m3': 'm3', 'voc_kg': 'kg',
        'waste_metal_kg': 'kg', 'waste_hazardous_kg': 'kg', 'waste_general_kg': 'kg', 'waste_packaging_kg': 'kg'}
SOURCE = {'electricity_kwh': 'Utility sub-meter', 'natural_gas_kwh': 'Utility sub-meter', 'water_m3': 'Utility sub-meter',
          'voc_kg': 'Paint consumption log', 'waste_metal_kg': 'Waste contractor manifest',
          'waste_hazardous_kg': 'Waste contractor manifest', 'waste_general_kg': 'Waste contractor manifest',
          'waste_packaging_kg': 'Waste contractor manifest'}
RECYCLE = {'waste_metal_kg': 0.95, 'waste_packaging_kg': 0.72, 'waste_general_kg': 0.18, 'waste_hazardous_kg': 0.10}
HEAT = {1: 1.0, 2: .9, 3: .7, 4: .45, 5: .2, 6: .05, 7: 0, 8: 0, 9: .1, 10: .4, 11: .75, 12: .95}
COOL = {6: .5, 7: 1.0, 8: 1.0, 9: .4}
loc_wc = {v: k for k, v in WC_LOC.items()}
# Ferraille issue des rebuts réels (cadres et pièces métalliques, 2,5 kg par pièce en moyenne)
scrap_kg = WO[(WO.StartDate >= START) & (WO.StartDate <= END) & (WO.ScrappedQty > 0)].copy()
scrap_kg['wc'] = scrap_kg.ScrapReasonID.astype(int).map(SCRAP_WC)
scrap_kg = (scrap_kg.groupby(['m', 'wc']).ScrappedQty.sum() * 2.5).to_dict()
env_rows = []
for m in MONTHS:
    for loc, inds in ENV_BASE.items():
        g = loc_wc.get(loc)
        a = idx[g][m] if g else idx['LOG'][m]
        for ind, base in inds.items():
            if ind == 'electricity_kwh':
                v = base * (0.45 + 0.55 * a)
            elif ind == 'natural_gas_kwh':
                v = base * (0.5 + 0.5 * a) * (1 + 0.35 * HEAT[m.month])
            else:
                v = base * a
            if ind == 'voc_kg' and loc == 40:
                d = date(m.year, m.month, 1)
                v *= 0.55 if d >= WATER_PAINT + timedelta(31) else (0.75 if d >= WATER_PAINT else 1.0)
            if ind == 'water_m3' and loc == 40 and date(m.year, m.month, 1) >= WATER_PAINT:
                v *= 1.15
            if ind == 'waste_hazardous_kg' and loc == 40 and date(m.year, m.month, 1) >= WATER_PAINT:
                v *= 0.7
            if ind == 'waste_metal_kg' and g:
                v += scrap_kg.get((m, g), 0)
            v *= rng.normal(1, 0.035)
            env_rows.append(dict(month=str(m), location_id=loc, indicator=ind, value=round(v, 1), unit=UNIT[ind], source=SOURCE[ind]))
            if ind in RECYCLE:
                env_rows.append(dict(month=str(m), location_id=loc, indicator=ind.replace('_kg', '_recycled_kg'),
                                     value=round(v * float(np.clip(rng.normal(RECYCLE[ind], 0.02), 0, 1)), 1), unit='kg',
                                     source='Waste contractor manifest'))
    # Bâtiment et services généraux (sans zone de production)
    heads = len(E) + (TEMP[TEMP.month == str(m)].temp_fte.sum() if len(TEMP) else 0)
    site = {'electricity_kwh': 45000 * (1 + 0.25 * COOL.get(m.month, 0) + 0.12 * HEAT[m.month]),
            'natural_gas_kwh': 62000 * HEAT[m.month] + 3000, 'water_m3': 0.55 * heads,
            'waste_general_kg': 5200 + 14 * heads}
    for ind, v in site.items():
        v *= rng.normal(1, 0.035)
        env_rows.append(dict(month=str(m), location_id=None, indicator=ind, value=round(v, 1), unit=UNIT[ind], source=SOURCE[ind]))
        if ind in RECYCLE:
            env_rows.append(dict(month=str(m), location_id=None, indicator=ind.replace('_kg', '_recycled_kg'),
                                 value=round(v * float(np.clip(rng.normal(RECYCLE[ind], 0.02), 0, 1)), 1), unit='kg',
                                 source='Waste contractor manifest'))
ENV = pd.DataFrame(env_rows)

# --------------------------------------------------------------------------- #
# 9. Export (bronze : CSV tels qu'exportés des systèmes sources)
# --------------------------------------------------------------------------- #
def write(df, folder, name, int_cols=()):
    os.makedirs(f'{OUT}/{folder}', exist_ok=True)
    df = df.copy()
    for c in int_cols:
        if c in df:
            df[c] = df[c].astype('Int64')
    for c in df.columns:
        if df[c].dtype == 'datetime64[ns]':
            df[c] = df[c].dt.strftime('%Y-%m-%dT%H:%M:%S')
    df.to_csv(f'{OUT}/{folder}/{name}.csv', index=False)
    return len(df)

counts = {
    'ehs/incidents': write(INC, 'ehs', 'incidents', ['location_id', 'injured_business_entity_id', 'reported_by_business_entity_id']),
    'ehs/training_catalog': write(CATALOG, 'ehs', 'training_catalog'),
    'ehs/training_records': write(TR, 'ehs', 'training_records'),
    'hr/timesheet_monthly': write(TS, 'hr', 'timesheet_monthly'),
    'hr/temp_labor_monthly': write(TEMP, 'hr', 'temp_labor_monthly'),
    'quality/audits': write(AUD, 'quality', 'audits', ['auditor_business_entity_id']),
    'quality/nonconformities': write(NC[['nc_id', 'detected_on', 'source', 'severity', 'description', 'work_center', 'location_id',
                                         'work_order_id', 'purchase_order_id', 'purchase_order_detail_id', 'vendor_id', 'audit_id',
                                         'rma_id', 'sales_order_id', 'product_id', 'scrap_reason_id', 'qty_affected',
                                         'estimated_cost_usd', 'root_cause_category', 'status', 'closed_on']],
                                     'quality', 'nonconformities',
                                     ['location_id', 'work_order_id', 'purchase_order_id', 'purchase_order_detail_id', 'vendor_id',
                                      'sales_order_id', 'product_id', 'scrap_reason_id', 'qty_affected']),
    'quality/customer_returns': write(RET, 'quality', 'customer_returns'),
    'environment/monthly_readings': write(ENV, 'environment', 'monthly_readings', ['location_id']),
    'reference/scenario_events': write(pd.DataFrame(EVENTS, columns=['event_date', 'scope', 'event', 'description']), 'reference', 'scenario_events'),
}
print(counts)


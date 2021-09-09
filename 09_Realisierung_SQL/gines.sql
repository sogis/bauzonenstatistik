-- Zusammenzug bebaute und unbebaute Parzellen nach Gemeinde, Zonentyp und bebauungsstatus
-- abgeleitet von Tabelle arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_bebauungsstand_pro_gemeinde
WITH np_typ_kt AS (
  SELECT DISTINCT grundnutzung_typ_kt, substring(grundnutzung_typ_kt FROM 2 FOR 3)::integer AS zonen_code,  
    substring(grundnutzung_typ_kt FROM 6) AS zonen_name
  FROM arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_bebauungsstand_pro_gemeinde
    ORDER BY grundnutzung_typ_kt ASC
),
gg AS (
 SELECT
    bfs_gemeindenummer,
    gemeindename
  FROM agi_hoheitsgrenzen_pub.hoheitsgrenzen_gemeindegrenze gg
    WHERE gg.bfs_gemeindenummer < 2410
    ORDER BY gg.bfs_gemeindenummer ASC
),
zonagg AS (
 SELECT 
  gg.bfs_gemeindenummer,
  gg.gemeindename,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=110))::numeric / 10000,2),0) AS n110_wohnzone_1_g_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=110))::numeric / 10000,2),0) AS n110_wohnzone_1_g_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=111))::numeric / 10000,2),0) AS n111_wohnzone_2_g_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=111))::numeric / 10000,2),0) AS n111_wohnzone_2_g_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=112))::numeric / 10000,2),0) AS n112_wohnzone_3_g_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=112))::numeric / 10000,2),0) AS n112_wohnzone_3_g_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=113))::numeric / 10000,2),0) AS n113_wohnzone_4_g_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=113))::numeric / 10000,2),0) AS n113_wohnzone_4_g_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=114))::numeric / 10000,2),0) AS n114_wohnzone_5_g_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=114))::numeric / 10000,2),0) AS n114_wohnzone_5_g_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=116))::numeric / 10000,2),0) AS n116_wohnzone_7_g_und_groesser_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=116))::numeric / 10000,2),0) AS n116_wohnzone_7_g_und_groesser_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=117))::numeric / 10000,2),0) AS n117_zone_fuer_terrassenhaeuser_terrassensiedlung_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=117))::numeric / 10000,2),0) AS n117_zone_fuer_terrassenhaeuser_terrassensiedlung_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=120))::numeric / 10000,2),0) AS n120_gewerbezone_ohne_wohnen_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=120))::numeric / 10000,2),0) AS n120_gewerbezone_ohne_wohnen_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=121))::numeric / 10000,2),0) AS n121_industriezone_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=121))::numeric / 10000,2),0) AS n121_industriezone_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=122))::numeric / 10000,2),0) AS n122_arbeitszone_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=122))::numeric / 10000,2),0) AS n122_arbeitszone_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=130))::numeric / 10000,2),0) AS n130_gewerbezone_mit_wohnen_mischzone_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=130))::numeric / 10000,2),0) AS n130_gewerbezone_mit_wohnen_mischzone_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=131))::numeric / 10000,2),0) AS n131_gewerbezone_mit_wohnen_mischzone_2_g_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=131))::numeric / 10000,2),0) AS n131_gewerbezone_mit_wohnen_mischzone_2_g_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=132))::numeric / 10000,2),0) AS n132_gewerbezone_mit_wohnen_mischzone_3_g_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=132))::numeric / 10000,2),0) AS n132_gewerbezone_mit_wohnen_mischzone_3_g_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=133))::numeric / 10000,2),0) AS n133_gewerbezone_mit_wohnen_mischzone_4_g_und_groesser_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=133))::numeric / 10000,2),0) AS n133_gewerbezone_mit_wohnen_mischzone_4_g_und_groesser_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=134))::numeric / 10000,2),0) AS n134_zone_fuer_publikumsintensive_anlagen_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=134))::numeric / 10000,2),0) AS n134_zone_fuer_publikumsintensive_anlagen_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=140))::numeric / 10000,2),0) AS n140_kernzone_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=140))::numeric / 10000,2),0) AS n140_kernzone_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=141))::numeric / 10000,2),0) AS n141_zentrumszone_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=141))::numeric / 10000,2),0) AS n141_zentrumszone_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=142))::numeric / 10000,2),0) AS n142_erhaltungszone_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=142))::numeric / 10000,2),0) AS n142_erhaltungszone_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=150))::numeric / 10000,2),0) AS n150_zone_fuer_oeffentliche_bauten_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=150))::numeric / 10000,2),0) AS n150_zone_fuer_oeffentliche_bauten_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=151))::numeric / 10000,2),0) AS n151_zone_fuer_oeffentliche_anlagen_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=151))::numeric / 10000,2),0) AS n151_zone_fuer_oeffentliche_anlagen_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=162))::numeric / 10000,2),0) AS n162_landwirtschaftliche_kernzone_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=162))::numeric / 10000,2),0) AS n162_landwirtschaftliche_kernzone_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=163))::numeric / 10000,2),0) AS n163_weilerzone_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=163))::numeric / 10000,2),0) AS n163_weilerzone_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=170))::numeric / 10000,2),0) AS n170_zone_fuer_freizeit_und_erholung_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=170))::numeric / 10000,2),0) AS n170_zone_fuer_freizeit_und_erholung_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=180))::numeric / 10000,2),0) AS n180_verkehrszone_strasse_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=180))::numeric / 10000,2),0) AS n180_verkehrszone_strasse_unbebaut,
  COALESCE(Round((SUM(lsbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=190))::numeric / 10000,2),0) AS n190_spezialzone_bebaut,
  COALESCE(Round((SUM(lsunbeb.flaeche_beschnitten) FILTER (WHERE np_typ_kt.zonen_code=190))::numeric / 10000,2),0) AS n190_spezialzone_unbebaut,
  COALESCE(Round((SUM(ST_Area(reserv.geometrie)) FILTER (WHERE reserv.typ_code_kommunal=4300))::numeric / 10000,2),0) AS n430_reservezone_wohnzone_mischzone_kernzone_zentrumszone,
  COALESCE(Round((SUM(ST_Area(reserv.geometrie)) FILTER (WHERE reserv.typ_code_kommunal=4310))::numeric / 10000,2),0) AS n431_reservezone_arbeiten,
  COALESCE(Round((SUM(ST_Area(reserv.geometrie)) FILTER (WHERE reserv.typ_code_kommunal=4320))::numeric / 10000,2),0) AS n432_reservezone_oe_ba--,
  --COALESCE(Round((SUM(ST_Area(gewaess.geometrie)) FILTER (WHERE np_typ_kt.zonen_code=320))::numeric / 10000,2),0) AS n320_gewaesser
FROM
  np_typ_kt CROSS JOIN gg
  LEFT JOIN arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_liegenschaft_nach_bebauungsstand lsbeb
    ON lsbeb.bfs_nr = gg.bfs_gemeindenummer AND lsbeb.grundnutzung_typ_kt LIKE '%'||np_typ_kt.grundnutzung_typ_kt||'%'
      AND lsbeb.bebauungsstand IN ('bebaut','teilweise_bebaut')
  LEFT JOIN arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_liegenschaft_nach_bebauungsstand lsunbeb
    ON lsunbeb.bfs_nr = gg.bfs_gemeindenummer AND lsunbeb.grundnutzung_typ_kt LIKE '%'||np_typ_kt.grundnutzung_typ_kt||'%'
      AND lsunbeb.bebauungsstand = 'unbebaut'
  LEFT JOIN arp_npl_pub.nutzungsplanung_grundnutzung reserv
    ON reserv.bfs_nr = gg.bfs_gemeindenummer
      AND reserv.typ_code_kommunal >= 4300 AND reserv.typ_code_kommunal < 4400 --Reservezonen 
--  LEFT JOIN arp_npl_pub.nutzungsplanung_grundnutzung gewaess
--    ON gewaess.bfs_nr = gg.bfs_gemeindenummer
--      AND gewaess.typ_kt = 'N320_Gewaesser' --Gewaesser 
  GROUP BY gg.bfs_gemeindenummer, gg.gemeindename
 )
 -- Schliesslich noch JOIN für Reservezonen un
 SELECT * FROM zonagg
;
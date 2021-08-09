DELETE FROM arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_bebauungsstand_mit_zonen_und_lsgrenzen WHERE bfs_nr = 2618;
INSERT
  INTO arp_auswertung_nutzungsplanung_pub.bauzonenstatistik_bebauungsstand_mit_zonen_und_lsgrenzen
   (grundnutzung_typ_kt,bebauungsstand,bfs_nr,gemeindename,flaeche,geometrie)
   
-- hier wird Gemeinde selektiert
-- TODO: muss in Gradle als Variable übernommen werden
WITH bfsnr AS (
	SELECT
	  2618 AS nr
     --Himmelried: 2618, Büsserach: 2614, Oensingen: 2407
),
-- Gemeindegeometrie
gem AS (
  SELECT
    geometrie,
    gemeindename,
    bfs_gemeindenummer
  FROM
    agi_hoheitsgrenzen_pub.hoheitsgrenzen_gemeindegrenze
   WHERE bfs_gemeindenummer = (SELECT nr FROM bfsnr)
),
-- Gebäude inkl. projektierten Gebäuden
geb AS (
  SELECT
    --positive buffer of 12m and then negative buffer of 6m
    --special buffer parameters 
    ST_Buffer(ST_Buffer(geometrie,12,'endcap=flat join=miter'),-6,'endcap=flat join=miter') AS geometrie
  FROM
    agi_mopublic_pub.mopublic_bodenbedeckung
   WHERE
    art_txt = 'Gebaeude'
    AND bfs_nr = (SELECT nr FROM bfsnr)
    AND ST_Area(geometrie) >= 25 --kleinere Gebäude werden ignoriert (gelten als abbrechbar)
 UNION
  SELECT
    --positive buffer of 12m and then negative buffer of 6m
    --special buffer parameters 
    ST_Buffer(ST_Buffer(geometrie,12,'endcap=flat join=miter'),-6,'endcap=flat join=miter') AS geometrie
  FROM
    agi_mopublic_pub.mopublic_bodenbedeckung_proj
   WHERE
    art_txt = 'Gebaeude'
    AND bfs_nr = (SELECT nr FROM bfsnr)
    AND ST_Area(geometrie) >= 25 --kleinere Gebäude werden ignoriert (gelten als abbrechbar)
),
-- Einzelbojekte
eob AS (
  SELECT
   ST_Buffer(geometrie,1,'endcap=flat join=miter') AS geometrie
  FROM agi_mopublic_pub.mopublic_einzelobjekt_flaeche
   WHERE
    bfs_nr = (SELECT nr FROM bfsnr)
    AND art_txt IN ('Unter-stand','unterirdisches_Gebaeude','uebriger_Gebaeudeteil','Reservoir','Aussichtsturm','Bahnsteig')
    AND ST_Area(geometrie) >= 25
),
-- Liegenschaften
gr AS (
  SELECT
   t_id,
   geometrie,
   ST_Buffer(ST_ExteriorRing(geometrie),4,'endcap=flat join=miter') AS geom_buff,
   nummer,
   egrid
  FROM agi_mopublic_pub.mopublic_grundstueck mg 
   WHERE
    art_txt = 'Liegenschaft'
    AND bfs_nr = (SELECT nr FROM bfsnr)
),
-- Nutzungszonen
nutzzon AS (
  SELECT
    t_id,
    geometrie,
    ST_Buffer(ST_Exteriorring(geometrie),4,'endcap=flat join=miter') AS geom_buff,
    typ_kt,
    bfs_nr
  FROM arp_npl_pub.nutzungsplanung_grundnutzung
    WHERE bfs_nr = (SELECT nr FROM bfsnr)
    AND typ_code_kommunal < 2000
    AND typ_kt NOT IN ('N160_Gruen_und_Freihaltezone_innerhalb_Bauzone','N161_kommunale_Uferschutzzone_innerhalb_Bauzone','N169_weitere_eingeschraenkte_Bauzonen','N180_Verkehrszone_Stras-se','N181_Verkehrszone_Bahnareal','N182_Verkehrszone_Flugplatzareal','N189_weitere_Verkehrszonen')
),
-- Dissolve (GIS Union) aller Nutzungszonen in Siedlungsflächen
nutzzon_dissolved_tmp AS (
  SELECT
    ST_Union(geometrie,0.001) AS geometrie
  FROM nutzzon
),
-- clean up narrow holes (data errors)
-- first step: dump geometries and rings
nutzzon_rings_tmp AS (
  SELECT
    (ST_DumpRings((st_dump(geometrie)).geom)).geom AS geometrie
  FROM nutzzon_dissolved_tmp
),
-- second intermediate step for cleaning: calculate inscribed circle
nutzzon_rings_tmp2 AS (
  SELECT
   geometrie,
   (ST_MaximumInscribedCircle(geometrie)).radius AS radius
  FROM nutzzon_rings_tmp
),
-- third and final step for cleaning: filter away small rings and rebuild polygons
-- also rejoin original attributes
nutzzon_dissolved AS (
  SELECT
   ST_BuildArea(ST_Collect(geometrie)) AS geometrie
  FROM nutzzon_rings_tmp2
   WHERE
     radius > 0.4 -- very narrow polygons with only 80cm width are filtered away
),
-- Verkehrsflächen
verkfl AS (
  SELECT
   ST_Buffer(geometrie,4,'endcap=flat join=miter') AS geometrie
  FROM agi_mopublic_pub.mopublic_bodenbedeckung mb 
   WHERE
    bfs_nr = (SELECT nr FROM bfsnr)
    AND art_txt = 'Strasse_Weg'
),
--Merge (SQL Union) aller nicht bebaubaren Flächen and clip it (ST_Intersection) to Nutzunszonen Siedlungsgebiet
--TODO: test if intersection would be faster if done after the  ST_Union() step below
nicht_bebaubar_tmp AS (
  SELECT ST_Intersection(geb.geometrie,nd.geometrie,0.001) AS geometrie FROM geb, nutzzon_dissolved nd WHERE ST_Intersects(geb.geometrie,nd.geometrie)
  UNION
  SELECT ST_Intersection(eob.geometrie,nd.geometrie,0.001) AS geometrie FROM eob, nutzzon_dissolved nd WHERE ST_Intersects(eob.geometrie,nd.geometrie)
  UNION
  SELECT ST_Intersection(verkfl.geometrie,nd.geometrie,0.001) AS geometrie FROM verkfl, nutzzon_dissolved nd WHERE ST_Intersects(verkfl.geometrie,nd.geometrie)
  UNION
  SELECT ST_Intersection(gr.geom_buff,nd.geometrie,0.001) AS geometrie FROM gr, nutzzon_dissolved nd WHERE ST_Intersects(gr.geometrie,nd.geometrie)
  UNION
  SELECT geom_buff AS geometrie FROM nutzzon
),
-- Dissolve (GIS Union) aller nicht bebaubaren Flächen
nicht_bebaubar AS (
  SELECT ST_Union(geometrie,0.001) AS geometrie FROM nicht_bebaubar_tmp
),
-- Calculate Difference between Nutzungszonen Siedlungsgebiet and bebaubaren Flächen, Dump them to individual polygons
bebaubar_tmp AS (
  SELECT (ST_Dump(ST_Difference(nd.geometrie,nbb.geometrie,0.001))).geom AS geometrie FROM nutzzon_dissolved nd, nicht_bebaubar nbb
),
-- filter away small parts of polygons < 180m2, negative buffer followed by positive buffer to get rid of very narrow polygon passages and spikes
double_buff AS (
  SELECT
     (ST_Dump(
      ST_Buffer(
        ST_Buffer(
          geometrie,
          -3,
          'endcap=flat join=miter mitre_limit=2.0'),
        3,
        'endcap=flat join=miter mitre_limit=2.0')
      )
    ).geom
    AS geometrie
  FROM
    bebaubar_tmp
   WHERE
     ST_Area(geometrie) >= 180
),
-- final version of unbebaute Flächen
-- filter small polygons away and calculate pole of inaccessibility with ST_MaximumInscribedCircle
unbebaut_final AS (
  SELECT
    (ST_MaximumInscribedCircle(geometrie)).radius AS radius,
    geometrie
  FROM double_buff
   WHERE
    ST_Area(geometrie) >= 180
),
-- ST_Union of unbebaut
unbebaut_dissolved AS (
  SELECT
    ST_Union(geometrie,0.001) AS geometrie
  FROM unbebaut_final
   WHERE
    radius > 5
)
,
-- final version of bebaute Flächen mit ST_Difference
bebaut_final AS (
  SELECT
    (ST_Dump(ST_Difference(nd.geometrie,unbb.geometrie,0.001))).geom AS geometrie
  FROM nutzzon_dissolved nd, unbebaut_dissolved unbb
),
gesamt_final AS (
	--SELECT nz.typ_kt AS grundnutzung_typ_kt, 'bebaut' AS bebauungsstand, nz.bfs_nr, gem.gemeindename, ST_Multi((ST_Dump(bb.geometrie)).geom) AS geometrie FROM bebaut_final bb
    SELECT nz.typ_kt AS grundnutzung_typ_kt, 'bebaut' AS bebauungsstand, nz.bfs_nr, gem.gemeindename, ST_Multi(ST_Intersection(bb.geometrie,nz.geometrie)) AS geometrie FROM nutzzon nz
	  LEFT JOIN bebaut_final bb ON ST_Intersects(ST_PointOnSurface(nz.geometrie),bb.geometrie)
      --LEFT JOIN nutzzon nz ON ST_Intersects(ST_PointOnSurface(bb.geometrie),nz.geometrie)
	  LEFT JOIN gem ON gem.bfs_gemeindenummer = nz.bfs_nr
	UNION
	SELECT nz.typ_kt AS grundnutzung_typ_kt, 'unbebaut' AS bebauungsstand, nz.bfs_nr, gem.gemeindename, ST_Multi((ST_Dump(ubb.geometrie)).geom) AS geometrie FROM unbebaut_dissolved ubb
	  LEFT JOIN nutzzon nz ON ST_Intersects(ST_PointOnSurface(ubb.geometrie),nz.geometrie)
	  LEFT JOIN gem ON gem.bfs_gemeindenummer = nz.bfs_nr
	 ORDER BY 1,2
)
-- areas (m2) can only be calculated at the very end after the ST_Dump()
SELECT 
  grundnutzung_typ_kt,
  bebauungsstand,
  bfs_nr,
  gemeindename,
  Round(ST_Area(geometrie)) AS flaeche,
  geometrie
FROM gesamt_final
  WHERE geometrie IS NOT NULL
;

# Registry (board-verified facts; target i.MX8MP GC7000UL, Godot 4.7.2 Mobile)

| id | path | license | size | board | traps |
|---|---|---|---|---|---|
| char.vitruvian | characters/vitruvian | CC0 (code MIT) | ~36k body+head | ok  | strip COLOR/TEXCOORD_1-3 from head GLB; hair cards never render; sclera needs ALPHA_SCISSOR; no SSS: use rim |
| char.vitruvian.hair_cards | characters/vitruvian (upstream hairtool_cards.glb) | CC0 | 162k verts alpha cards | fail no frame within 15 min, twice |  |
| prop.scooter | props/scooter.gd | ours MIT | 7 primitives | ok 40 instances free |  |
| mat.ambientcg | materials/ambientcg | CC0 | 5 × 1K color+rough | ok  |  |
| signs.gen | signs/gen_signs.py | ours (font OFL) | — | ok emission ≤ 0.6 or glow whites out |  |
| shader.building | shaders/building.gdshader | — | — | ok  |  |
| shader.road | shaders/road.gdshader | — | — | ok  |  |
| mocap.dream-wings | mocap/dream-wings/mocap.json | derived, internal only | 699 | ok  |  |
| kit.rooftop | buildings/rooftop_kit.gd | ours MIT | tank/antenna/shed/parapet/trees/AC/balconies | ok no FPS change | triplanar repeats-per-metre; Tiles074 ≥4/m only |
| shader.building.day | shaders/building.gdshader night=0 | ours | 2 samplers | ok | no return in fragment() |
| vehicle.procar | vehicles/procar.gd | ours MIT | ~40 primitives | ok 10 cars + facades in chase stills | metallic paint goes dark at night: keep albedo bright |

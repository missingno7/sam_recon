"""Re-run the bounded suite without writing outside this worker directory."""
from research import *
import runtime_probe,system_recipe,full_runtime_probe,directive_probe,extra_probes,layout_probe,discriminant,catalogue_probe
def run():
    for v in ('50','55','60','70'):compile(v,RICH,'RICH')
    census()
    runtime_probe.run()
    system_recipe.run()
    for ep in ('sam1','sam2','sam3'):full_runtime_probe.run(ep)
    directive_probe.run()
    results={'external':extra_probes.external_probe(),'memory':extra_probes.memory_probe(),
             'compatibility':extra_probes.compatibility_probe(),'forward':extra_probes.forward_probe()}
    (ROOT/'extra_results.json').write_text(json.dumps(results,indent=2))
    layout_probe.run();discriminant.run();catalogue_probe.run()
    print('All probes completed; byte-exact runtime assertions passed for every episode.')
if __name__=='__main__':run()

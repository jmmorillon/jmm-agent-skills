# Backlog

## À faire
- [ ] Créer `/complete-knowledge` : cibler une connaissance existante — en particulier une note autonome préexistante, longue et sans Q/R — pour la reformater au gabarit de fiche et la compléter. Seul skill autorisé à écrire dans les notes autonomes.
- [ ] Optimiser la description de `project-docs-sync` pour le déclenchement (loop skill-creator `run_loop.py`, ~5 itérations) si le skill sur- ou sous-déclenche à l'usage.
- [ ] Rejouer `/check-knowledge` **un autre jour** que celui de la capture — c'est le seul cas qui expose une régression sur la date du jour, et la fumigation initiale est tombée le jour des exemples.
- [ ] Éprouver `/add-knowledge` sur un sujet couvert par une note préexistante, pour vérifier que la clôture d'écriture tient.
- [ ] Décider si le dépôt devient un plugin `jmm:` (namespace/préfixe des skills) ou reste sur le mécanisme de symlinks — arbitrage laissé ouvert le 2026-07-22.

## En cours
- [ ] Éprouver `project-docs-sync` sur de vrais projets et affiner à l'usage (approche retenue plutôt que des evals formelles).
- [ ] Éprouver `/add-journal` en session réelle, en particulier son déclenchement : l'optimisation de description par `run_loop.py` n'a rien pu départager. Reprendre la description à partir des formulations qui ne déclenchent pas.

## Fait
- [x] Créer le skill `add-journal` et l'évaluer sur des copies du vault (3 cas, avec et sans skill).
- [x] Créer le skill `writing-pr`.
- [x] Créer les skills `add-knowledge` et `check-knowledge` (spec et plan sous `docs/superpowers/`).
- [x] Fumiger les deux skills en session réelle : 3 fiches capturées, pas de doublon, index et état de révision corrects, boucle de retour déclenchée (une révision a produit une fiche supplémentaire).
- [x] `install.sh` : installation des plugins tiers + sous-agents (bootstrap machine complet).
- [x] Versionner les définitions de sous-agents (`agents/code-improver.md`).
- [x] Retirer la convention de préfixe `jmm-` sur les skills (`obsidian-para-sorter`).
- [x] Créer le skill `project-docs-sync` (+ `references/doc-frameworks.md`).

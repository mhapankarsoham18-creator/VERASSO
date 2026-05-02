import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/neo_pixel_box.dart';
import 'globe_screen.dart';
import 'simulation_viewer.dart';

/// Data model for a single simulation entry.
class _SimEntry {
  final String title;
  final String asset;
  final IconData icon;
  const _SimEntry(this.title, this.asset, this.icon);
}

/// Data model for a subject category.
class _SubjectSection {
  final String name;
  final IconData headerIcon;
  final Color accent;
  final List<_SimEntry> sims;
  const _SubjectSection(this.name, this.headerIcon, this.accent, this.sims);
}

// ─── SIMULATION CATALOG ─────────────────────────────────────
const _catalog = <_SubjectSection>[
  // ╔══════════════════════════════════════════╗
  // ║  PHYSICS  (50)                           ║
  // ╚══════════════════════════════════════════╝
  _SubjectSection('PHYSICS', Icons.science, Color(0xFF2196F3), [
    _SimEntry('Energy Skate Park', 'assets/simulations/physics/energy-skate-park-basics.html', Icons.downhill_skiing),
    _SimEntry('Gravity Force Lab', 'assets/simulations/physics/gravity-force-lab.html', Icons.fitness_center),
    _SimEntry('Gravity Force Lab: Basics', 'assets/simulations/physics/gravity-force-lab-basics.html', Icons.fitness_center),
    _SimEntry('Forces & Motion: Basics', 'assets/simulations/physics/forces-and-motion-basics.html', Icons.swap_horiz),
    _SimEntry('Projectile Motion', 'assets/simulations/physics/projectile-motion.html', Icons.rocket_launch),
    _SimEntry('Pendulum Lab', 'assets/simulations/physics/pendulum-lab.html', Icons.access_time),
    _SimEntry('Masses & Springs', 'assets/simulations/physics/masses-and-springs.html', Icons.linear_scale),
    _SimEntry('Masses & Springs: Basics', 'assets/simulations/physics/masses-and-springs-basics.html', Icons.linear_scale),
    _SimEntry("Hooke's Law", 'assets/simulations/physics/hookes-law.html', Icons.expand),
    _SimEntry('Wave on a String', 'assets/simulations/physics/wave-on-a-string.html', Icons.waves),
    _SimEntry('Waves: Intro', 'assets/simulations/physics/waves-intro.html', Icons.waves),
    _SimEntry('Wave Interference', 'assets/simulations/physics/wave-interference.html', Icons.blur_circular),
    _SimEntry('Circuit Builder (DC)', 'assets/simulations/physics/circuit-construction-kit-dc.html', Icons.electrical_services),
    _SimEntry('Circuit Builder (Virtual)', 'assets/simulations/physics/circuit-construction-kit-dc-virtual-lab.html', Icons.electrical_services),
    _SimEntry("Ohm's Law", 'assets/simulations/physics/ohms-law.html', Icons.bolt),
    _SimEntry('Resistance in a Wire', 'assets/simulations/physics/resistance-in-a-wire.html', Icons.cable),
    _SimEntry("Faraday's Law", 'assets/simulations/physics/faradays-law.html', Icons.rotate_right),
    _SimEntry("Coulomb's Law", 'assets/simulations/physics/coulombs-law.html', Icons.flash_on),
    _SimEntry('Charges & Fields', 'assets/simulations/physics/charges-and-fields.html', Icons.grid_on),
    _SimEntry('Capacitor Lab: Basics', 'assets/simulations/physics/capacitor-lab-basics.html', Icons.battery_charging_full),
    _SimEntry('John Travoltage', 'assets/simulations/physics/john-travoltage.html', Icons.person),
    _SimEntry('Balloons & Static', 'assets/simulations/physics/balloons-and-static-electricity.html', Icons.cloud),
    _SimEntry('Friction', 'assets/simulations/physics/friction.html', Icons.touch_app),
    _SimEntry('Geometric Optics', 'assets/simulations/physics/geometric-optics.html', Icons.visibility),
    _SimEntry('Geometric Optics: Basics', 'assets/simulations/physics/geometric-optics-basics.html', Icons.visibility),
    _SimEntry('Bending Light', 'assets/simulations/physics/bending-light.html', Icons.wb_sunny),
    _SimEntry('Color Vision', 'assets/simulations/physics/color-vision.html', Icons.palette),
    _SimEntry('Blackbody Spectrum', 'assets/simulations/physics/blackbody-spectrum.html', Icons.thermostat),
    _SimEntry('Greenhouse Effect', 'assets/simulations/physics/greenhouse-effect.html', Icons.eco),
    _SimEntry('My Solar System', 'assets/simulations/physics/my-solar-system.html', Icons.public),
    _SimEntry("Kepler's Laws", 'assets/simulations/physics/keplers-laws.html', Icons.track_changes),
    _SimEntry('Density', 'assets/simulations/physics/density.html', Icons.science),
    _SimEntry('Buoyancy', 'assets/simulations/physics/buoyancy.html', Icons.water),
    _SimEntry('Buoyancy: Basics', 'assets/simulations/physics/buoyancy-basics.html', Icons.water),
    _SimEntry('Under Pressure', 'assets/simulations/physics/under-pressure.html', Icons.compress),
    _SimEntry('Gas Properties', 'assets/simulations/physics/gas-properties.html', Icons.air),
    _SimEntry('Gases: Intro', 'assets/simulations/physics/gases-intro.html', Icons.air),
    _SimEntry('Diffusion', 'assets/simulations/physics/diffusion.html', Icons.blur_on),
    _SimEntry('Energy Forms & Changes', 'assets/simulations/physics/energy-forms-and-changes.html', Icons.power),
    _SimEntry('States of Matter', 'assets/simulations/physics/states-of-matter.html', Icons.ac_unit),
    _SimEntry('States of Matter: Basics', 'assets/simulations/physics/states-of-matter-basics.html', Icons.ac_unit),
    _SimEntry('Vector Addition', 'assets/simulations/physics/vector-addition.html', Icons.call_made),
    _SimEntry('Projectile Data Lab', 'assets/simulations/physics/projectile-data-lab.html', Icons.analytics),
    _SimEntry('Gravity & Orbits', 'assets/simulations/physics/gravity-and-orbits.html', Icons.public),
    _SimEntry('Collision Lab', 'assets/simulations/physics/collision-lab.html', Icons.compare_arrows),
    _SimEntry('Center & Variability', 'assets/simulations/physics/center-and-variability.html', Icons.bar_chart),
    _SimEntry('Mean: Share & Balance', 'assets/simulations/physics/mean-share-and-balance.html', Icons.balance),
    _SimEntry('Number Line: Distance', 'assets/simulations/physics/number-line-distance.html', Icons.straighten),
    _SimEntry('Number Line: Operations', 'assets/simulations/physics/number-line-operations.html', Icons.straighten),
    _SimEntry('Kinetics & Gravity', 'assets/simulations/physics/index.html', Icons.science),
  ]),

  // ╔══════════════════════════════════════════╗
  // ║  CHEMISTRY  (26)                         ║
  // ╚══════════════════════════════════════════╝
  _SubjectSection('CHEMISTRY', Icons.science_outlined, Color(0xFFFF9800), [
    _SimEntry('Build an Atom', 'assets/simulations/chemistry/build-an-atom.html', Icons.bubble_chart),
    _SimEntry('Isotopes & Atomic Mass', 'assets/simulations/chemistry/isotopes-and-atomic-mass.html', Icons.filter_tilt_shift),
    _SimEntry('Atomic Interactions', 'assets/simulations/chemistry/atomic-interactions.html', Icons.grain),
    _SimEntry('Molecule Shapes', 'assets/simulations/chemistry/molecule-shapes.html', Icons.view_in_ar),
    _SimEntry('Molecule Shapes: Basics', 'assets/simulations/chemistry/molecule-shapes-basics.html', Icons.view_in_ar),
    _SimEntry('Molecule Polarity', 'assets/simulations/chemistry/molecule-polarity.html', Icons.swap_vert),
    _SimEntry('Balancing Equations', 'assets/simulations/chemistry/balancing-chemical-equations.html', Icons.balance),
    _SimEntry('Reactants & Products', 'assets/simulations/chemistry/reactants-products-and-leftovers.html', Icons.science_outlined),
    _SimEntry('pH Scale', 'assets/simulations/chemistry/ph-scale.html', Icons.opacity),
    _SimEntry('pH Scale: Basics', 'assets/simulations/chemistry/ph-scale-basics.html', Icons.opacity),
    _SimEntry('Acid-Base Solutions', 'assets/simulations/chemistry/acid-base-solutions.html', Icons.local_drink),
    _SimEntry('Concentration', 'assets/simulations/chemistry/concentration.html', Icons.colorize),
    _SimEntry('Molarity', 'assets/simulations/chemistry/molarity.html', Icons.science),
    _SimEntry("Beer's Law Lab", 'assets/simulations/chemistry/beers-law-lab.html', Icons.wb_sunny),
    _SimEntry('Rutherford Scattering', 'assets/simulations/chemistry/rutherford-scattering.html', Icons.track_changes),
    _SimEntry('Hydrogen Atom Models', 'assets/simulations/chemistry/models-of-the-hydrogen-atom.html', Icons.circle_outlined),
    _SimEntry('Build a Nucleus', 'assets/simulations/chemistry/build-a-nucleus.html', Icons.blur_circular),
    _SimEntry('Gas Properties', 'assets/simulations/chemistry/gas-properties.html', Icons.air),
    _SimEntry('Gases: Intro', 'assets/simulations/chemistry/gases-intro.html', Icons.air),
    _SimEntry('Diffusion', 'assets/simulations/chemistry/diffusion.html', Icons.blur_on),
    _SimEntry('States of Matter', 'assets/simulations/chemistry/states-of-matter.html', Icons.ac_unit),
    _SimEntry('States of Matter: Basics', 'assets/simulations/chemistry/states-of-matter-basics.html', Icons.ac_unit),
    _SimEntry('Density', 'assets/simulations/chemistry/density.html', Icons.science),
    _SimEntry('Blackbody Spectrum', 'assets/simulations/chemistry/blackbody-spectrum.html', Icons.thermostat),
    _SimEntry('Energy Forms & Changes', 'assets/simulations/chemistry/energy-forms-and-changes.html', Icons.power),
    _SimEntry('Brownian Thermodynamics', 'assets/simulations/chemistry/index.html', Icons.whatshot),
  ]),

  // ╔══════════════════════════════════════════╗
  // ║  BIOLOGY  (6)                            ║
  // ╚══════════════════════════════════════════╝
  _SubjectSection('BIOLOGY', Icons.biotech, Color(0xFF4CAF50), [
    _SimEntry('Natural Selection', 'assets/simulations/biology/natural-selection.html', Icons.pets),
    _SimEntry('Gene Expression', 'assets/simulations/biology/gene-expression-essentials.html', Icons.biotech),
    _SimEntry('Neuron', 'assets/simulations/biology/neuron.html', Icons.psychology),
    _SimEntry('Color Vision', 'assets/simulations/biology/color-vision.html', Icons.remove_red_eye),
    _SimEntry('Greenhouse Effect', 'assets/simulations/biology/greenhouse-effect.html', Icons.eco),
    _SimEntry('Cellular Automata', 'assets/simulations/biology/cellular-automata.html', Icons.grid_on),
  ]),

  // ╔══════════════════════════════════════════╗
  // ║  GEOGRAPHY  (24)                         ║
  // ╚══════════════════════════════════════════╝
  _SubjectSection('GEOGRAPHY', Icons.public, Color(0xFF00BCD4), [
    _SimEntry('Terrain Engine', 'assets/simulations/geography/terrain-viewer.html', Icons.terrain),
    _SimEntry('Plate Tectonics', 'assets/simulations/geography/plate-tectonics.html', Icons.layers),
    _SimEntry('Weather Systems', 'assets/simulations/geography/weather-systems.html', Icons.thunderstorm),
    _SimEntry('Water Cycle', 'assets/simulations/geography/water-cycle.html', Icons.water_drop),
    _SimEntry('Volcano Simulator', 'assets/simulations/geography/volcano-simulator.html', Icons.local_fire_department),
    _SimEntry('Ocean Currents', 'assets/simulations/geography/ocean-currents.html', Icons.waves),
    _SimEntry('Erosion Simulator', 'assets/simulations/geography/erosion-simulator.html', Icons.landscape),
    _SimEntry('Climate Zones', 'assets/simulations/geography/climate-zones.html', Icons.thermostat),
    _SimEntry('Solar System Scale', 'assets/simulations/geography/solar-system-scale.html', Icons.circle),
    _SimEntry('Time Zones', 'assets/simulations/geography/time-zones.html', Icons.schedule),
    _SimEntry('Population Density', 'assets/simulations/geography/population-density.html', Icons.people),
    _SimEntry('Compass & Navigation', 'assets/simulations/geography/compass-navigation.html', Icons.explore),
    _SimEntry('Rock Cycle', 'assets/simulations/geography/rock-cycle.html', Icons.hexagon),
    _SimEntry('Seismic Waves', 'assets/simulations/geography/earthquake-waves.html', Icons.vibration),
    _SimEntry('Biomes Explorer', 'assets/simulations/geography/biomes.html', Icons.forest),
    _SimEntry('Continental Drift', 'assets/simulations/geography/continental-drift.html', Icons.map),
    _SimEntry('River Delta Formation', 'assets/simulations/geography/river-delta.html', Icons.water),
    _SimEntry('Glacial Movement', 'assets/simulations/geography/glacial-movement.html', Icons.ac_unit),
    _SimEntry('Global Wind Patterns', 'assets/simulations/geography/wind-patterns.html', Icons.air),
    _SimEntry('Tidal Simulator', 'assets/simulations/geography/tidal-simulator.html', Icons.water),
    _SimEntry('Seasons Simulator', 'assets/simulations/geography/seasons.html', Icons.wb_sunny),
    _SimEntry('Aurora Borealis', 'assets/simulations/geography/aurora.html', Icons.auto_awesome),
    _SimEntry('Latitude & Longitude', 'assets/simulations/geography/latitude-longitude.html', Icons.grid_on),
    _SimEntry('Global Atlas 3D', 'assets/simulations/geography/index.html', Icons.public),
  ]),

  // ╔══════════════════════════════════════════╗
  // ║  HISTORY  (4)                            ║
  // ╚══════════════════════════════════════════╝
  _SubjectSection('HISTORY', Icons.history_edu, Color(0xFFFFAB00), [
    _SimEntry('Time Machine', 'assets/simulations/history/index.html', Icons.schedule),
    _SimEntry('Ancient Civilizations', 'assets/simulations/history/ancient-civilizations.html', Icons.account_balance),
    _SimEntry('World Wars Timeline', 'assets/simulations/history/world-wars.html', Icons.flag),
    _SimEntry('Industrial Revolution', 'assets/simulations/history/industrial-revolution.html', Icons.factory),
  ]),

  // ╔══════════════════════════════════════════╗
  // ║  COMMERCE  (10)                          ║
  // ╚══════════════════════════════════════════╝
  _SubjectSection('COMMERCE', Icons.trending_up, Color(0xFF66BB6A), [
    _SimEntry('Market Simulator', 'assets/simulations/commerce/index.html', Icons.timeline),
    _SimEntry('Supply & Demand', 'assets/simulations/commerce/supply-demand.html', Icons.show_chart),
    _SimEntry('Banking Simulator', 'assets/simulations/commerce/banking-sim.html', Icons.account_balance),
    _SimEntry('Currency Exchange', 'assets/simulations/commerce/currency-exchange.html', Icons.currency_exchange),
    _SimEntry('Budget Planner', 'assets/simulations/commerce/budget-planner.html', Icons.pie_chart),
    _SimEntry('Inflation Calculator', 'assets/simulations/commerce/inflation-calc.html', Icons.trending_down),
    _SimEntry('GDP Tracker', 'assets/simulations/commerce/gdp-tracker.html', Icons.bar_chart),
    _SimEntry('Trade Routes', 'assets/simulations/commerce/trade-routes.html', Icons.route),
    _SimEntry('Startup Simulator', 'assets/simulations/commerce/entrepreneurship.html', Icons.rocket_launch),
    _SimEntry('Tax Calculator', 'assets/simulations/commerce/tax-calculator.html', Icons.receipt_long),
  ]),

  // ╔══════════════════════════════════════════╗
  // ║  COMPUTER SCIENCE  (15)                  ║
  // ╚══════════════════════════════════════════╝
  _SubjectSection('COMPUTER SCIENCE', Icons.terminal, Color(0xFF00E676), [
    _SimEntry('Binary Counter', 'assets/simulations/cs/binary-counter.html', Icons.pin),
    _SimEntry('Sorting Algorithms', 'assets/simulations/cs/sorting-visualizer.html', Icons.sort),
    _SimEntry('Pathfinding A*', 'assets/simulations/cs/pathfinding.html', Icons.route),
    _SimEntry('Stack & Queue', 'assets/simulations/cs/stack-queue.html', Icons.storage),
    _SimEntry('Binary Search Tree', 'assets/simulations/cs/binary-tree.html', Icons.account_tree),
    _SimEntry('Logic Gates', 'assets/simulations/cs/logic-gates.html', Icons.memory),
    _SimEntry('CPU Pipeline', 'assets/simulations/cs/cpu-pipeline.html', Icons.developer_board),
    _SimEntry('Memory Allocation', 'assets/simulations/cs/memory-alloc.html', Icons.grid_view),
    _SimEntry('Encryption Demo', 'assets/simulations/cs/encryption-demo.html', Icons.lock),
    _SimEntry('Graph Traversal (BFS)', 'assets/simulations/cs/graph-traversal.html', Icons.hub),
    _SimEntry('Recursion Visualizer', 'assets/simulations/cs/recursion-viz.html', Icons.park),
    _SimEntry('Regex Tester', 'assets/simulations/cs/regex-tester.html', Icons.text_fields),
    _SimEntry('HTTP Request Flow', 'assets/simulations/cs/http-flow.html', Icons.cloud_sync),
    _SimEntry('Database Queries', 'assets/simulations/cs/database-query.html', Icons.table_chart),
  ]),

  // ╔══════════════════════════════════════════╗
  // ║  PHARMACY  (3)                           ║
  // ╚══════════════════════════════════════════╝
  _SubjectSection('PHARMACY', Icons.medication, Color(0xFF9C27B0), [
    _SimEntry('ADME Simulator', 'assets/simulations/pharmacy/adme-simulator.html', Icons.show_chart),
    _SimEntry('Tablet Compression Lab', 'assets/simulations/pharmacy/tablet-press.html', Icons.precision_manufacturing),
    _SimEntry('Clinical Dose Adjuster', 'assets/simulations/pharmacy/clinic-case.html', Icons.medical_services),
  ]),
];

// ─── MAIN DIRECTORY WIDGET ──────────────────────────────────
class SimulationsDirectory extends StatefulWidget {
  const SimulationsDirectory({super.key});

  @override
  State<SimulationsDirectory> createState() => _SimulationsDirectoryState();
}

class _SimulationsDirectoryState extends State<SimulationsDirectory> {
  /// Tracks which sections are expanded. All start expanded.
  late final List<bool> _expanded;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _expanded = List.filled(_catalog.length, false);
    // Expand the first section by default
    if (_expanded.isNotEmpty) _expanded[0] = true;
  }

  int get _totalSimCount =>
      _catalog.fold<int>(0, (sum, s) => sum + s.sims.length);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          color: Color(0xFFD32F2F),
          child: Column(
            children: [
              // ── HEADER ──
              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: NeoPixelBox(
                  padding: 10,
                  backgroundColor: Colors.black,
                  child: Row(
                    children: [
                      Icon(Icons.backpack, color: context.colors.primary, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'STUDY_TOOLS  ($_totalSimCount modules)',
                          style: TextStyle(
                            fontFamily: 'Courier',
                            fontWeight: FontWeight.w900,
                            color: context.colors.primary,
                            fontSize: 15,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── SEARCH BAR ──
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: NeoPixelBox(
                  padding: 0,
                  backgroundColor: Color(0xFFEEEEEE),
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v.toLowerCase()),
                    style: TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search simulations...',
                      hintStyle: TextStyle(fontFamily: 'Courier', color: Colors.black38),
                      prefixIcon: Icon(Icons.search, color: Colors.black45),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),

              // ── SIMULATION LIST ──
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _catalog.length,
                  itemBuilder: (context, sectionIdx) {
                    final section = _catalog[sectionIdx];
                    final filteredSims = _search.isEmpty
                        ? section.sims
                        : section.sims
                            .where((s) => s.title.toLowerCase().contains(_search))
                            .toList();

                    if (filteredSims.isEmpty && _search.isNotEmpty) {
                      return SizedBox.shrink();
                    }

                    final isExpanded = _search.isNotEmpty || _expanded[sectionIdx];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 8),
                        // ── Subject Header (tap to expand/collapse) ──
                        GestureDetector(
                          onTap: () => setState(() =>
                              _expanded[sectionIdx] = !_expanded[sectionIdx]),
                          child: NeoPixelBox(
                            padding: 12,
                            backgroundColor: Colors.black,
                            child: Row(
                              children: [
                                Icon(section.headerIcon,
                                    color: section.accent, size: 22),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${section.name}  (${filteredSims.length})',
                                    style: TextStyle(
                                      fontFamily: 'Courier',
                                      fontWeight: FontWeight.w900,
                                      color: section.accent,
                                      fontSize: 14,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                                Icon(
                                  isExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: section.accent,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Sim entries (when expanded) ──
                        if (isExpanded)
                          ...filteredSims.map((sim) => Padding(
                                padding: EdgeInsets.only(top: 6),
                                child: _SimTile(
                                  sim: sim,
                                  accent: section.accent,
                                ),
                              )),
                      ],
                    );
                  },
                ),
              ),

              // ── BOTTOM LIGHTS ──
              Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _pokedexDot(Colors.yellow),
                    _pokedexDot(Colors.green),
                    _pokedexDot(context.colors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pokedexDot(Color c) => Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: c,
          border: Border.all(color: Colors.black, width: 2),
          shape: BoxShape.circle,
        ),
      );
}

// ─── INDIVIDUAL SIM TILE ────────────────────────────────────
class _SimTile extends StatelessWidget {
  final _SimEntry sim;
  final Color accent;
  const _SimTile({required this.sim, required this.accent});

  @override
  Widget build(BuildContext context) {
    return NeoPixelBox(
      isButton: true,
      onTap: () => _openSim(context),
      padding: 12,
      backgroundColor: Color(0xFFEEEEEE),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(sim.icon, color: accent, size: 18),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              sim.title,
              style: TextStyle(
                fontFamily: 'Courier',
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.play_arrow_rounded, color: accent, size: 22),
        ],
      ),
    );
  }

  void _openSim(BuildContext context) {
    // Special case for Globe 3D
    if (sim.asset == 'assets/simulations/geography/index.html') {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => GlobeScreen()));
      return;
    }
    // Default: open in generic sim viewer
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimulationViewer(
          title: sim.title.toUpperCase(),
          simPath: sim.asset,
        ),
      ),
    );
  }
}

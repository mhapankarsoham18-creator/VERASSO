import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:verasso/core/ui/glass_container.dart';
import 'package:verasso/core/ui/liquid_background.dart';

import '../dynamics/escape_velocity_lab_screen.dart';
import '../dynamics/gravity_lab_screen.dart';
import '../dynamics/spring_lab_screen.dart';
import '../electromagnetism/circuit_lab_screen.dart';
import '../kinematics/kinematics_1d_lab_screen.dart';
import '../kinematics/projectile_lab_screen.dart';
import '../optics/refraction_lab_screen.dart';
import '../thermodynamics/gas_law_lab_screen.dart';
import '../waves/doppler_lab_screen.dart';
import '../waves/pendulum_lab_screen.dart';
import '../waves/wave_lab_screen.dart';
import 'interference_sim_screen.dart';
import 'projectile_motion_simulation.dart';

/// A screen that displays a menu of available physics simulations, categorized by topic.
class PhysicsMenuScreen extends StatelessWidget {
  /// Creates a [PhysicsMenuScreen] instance.
  const PhysicsMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Physics Lab'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Kinematics'),
              Tab(text: 'Dynamics'),
              Tab(text: 'Waves'),
              Tab(text: 'Optics'),
              Tab(text: 'Electricity'),
              Tab(text: 'Thermodynamics'),
            ],
          ),
        ),
        body: LiquidBackground(
          child: TabBarView(
            children: [
              // Kinematics
              _buildSimList(context, [
                _SimItem(
                    '1D Motion',
                    'Velocity & Acceleration',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const Kinematics1DLabScreen()))),
                _SimItem(
                    'Projectile Motion',
                    '2D Trajectories',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProjectileLabScreen()))),
                _SimItem(
                    'Cannon Challenge',
                    'Hit the Target!',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ProjectileMotionSimulation()))),
              ]),
              // Dynamics
              _buildSimList(context, [
                _SimItem(
                    'Gravity Lab',
                    'Free Fall & Bouncing',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GravityLabScreen()))),
                _SimItem(
                    'Spring System',
                    'Hooke\'s Law & Damping',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SpringLabScreen()))),
                _SimItem(
                    'Escape Velocity',
                    'Gravitational Escape',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const EscapeVelocityLabScreen()))),
              ]),
              // Waves
              _buildSimList(context, [
                _SimItem(
                    'Simple Pendulum',
                    'Harmonic Motion',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PendulumLabScreen()))),
                _SimItem(
                    'Wave Machine',
                    'Amplitude & Frequency',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WaveLabScreen()))),
                _SimItem(
                    'Doppler Effect',
                    'Sound Waves & Speed',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const DopplerLabScreen()))),
              ]),
              // Optics
              _buildSimList(context, [
                _SimItem(
                    'Refraction',
                    'Snell\'s Law',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RefractionLabScreen()))),
                _SimItem(
                    'Wave Interference',
                    'Double Slit Experiment',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const InterferenceSimScreen()))),
              ]),
              // Electricity
              _buildSimList(context, [
                _SimItem(
                    'Circuit Lab',
                    'Ohm\'s Law & Power',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CircuitLabScreen()))),
              ]),
              // Thermodynamics
              _buildSimList(context, [
                _SimItem(
                    'Ideal Gas Law',
                    'Pressure, Volume & Temp',
                    () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GasLawLabScreen()))),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimList(BuildContext context, List<_SimItem> sims) {
    return ListView(
      padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
      children: sims
          .map((sim) => GestureDetector(
                onTap: sim.onTap,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.playCircle,
                            color: Colors.white, size: 30),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sim.title,
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            Text(sim.subtitle,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white60)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

class _SimItem {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _SimItem(this.title, this.subtitle, this.onTap);
}

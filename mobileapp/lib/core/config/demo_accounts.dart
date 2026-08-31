/// Demo accounts seeded on Railway Postgres (password: demo123).
class DemoAccounts {
  DemoAccounts._();

  static const demoPassword = 'demo123';

  static const accounts = <DemoAccount>[
    DemoAccount('Pharmacy', 'pharmacy@sample.dukaplus.co.tz', 'Owner'),
    DemoAccount('Retail', 'retail@sample.dukaplus.co.tz', 'Owner'),
    DemoAccount('Restaurant', 'restaurant@sample.dukaplus.co.tz', 'Owner'),
    DemoAccount('Hardware', 'hardware@sample.dukaplus.co.tz', 'Owner'),
    DemoAccount('Electronics', 'electronics@sample.dukaplus.co.tz', 'Owner'),
    DemoAccount('Supermarket', 'supermarket@sample.dukaplus.co.tz', 'Owner'),
    DemoAccount('Manager', 'manager.kariakoo-pharmacy@sample.dukaplus.co.tz', 'Manager'),
    DemoAccount('Cashier', 'cashier.mbezi-retail@sample.dukaplus.co.tz', 'Cashier'),
  ];
}

class DemoAccount {
  final String label;
  final String email;
  final String role;

  const DemoAccount(this.label, this.email, this.role);
}

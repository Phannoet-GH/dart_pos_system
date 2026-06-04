enum Role{

  admin(value: 'admin', label: 'Administrator'),
  sale(value: 'sale', label: 'Sales Associate');

  final String value;
  final String label;
  const Role({
    required this.value,
    required this.label,
  });

}
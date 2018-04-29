kind =
  case year
  when 1850..1889 then 'Blues'
  when 1890..1909 then 'Ragtime'
  when 1910..1929 then 'New Orleans Jazz and a very long text for a line break'
  when 1930..1939 then 'Swing'
  when 1940..1950 then 'Bebop'
  else 'Jazz'
  end
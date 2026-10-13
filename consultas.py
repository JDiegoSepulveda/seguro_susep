from conexao import conexao

try:
   with conexao.cursor() as cursor:
      consulta = """
            SELECT
                LEFT(ano_mes,4) ano,
                SUM(premio_dir) total_premios_diretos
            FROM uf2
            GROUP BY ano
            ORDER BY ano;
        """

      cursor.execute(consulta)
      resultados = cursor.fetchall()

      for linha in resultados:
         print(
            f'Ano: {linha['ano']}'
            f'Prêmios diretos: R$ '
            f'{linha['total_premios_diretos']:.2f}'
         )
finally:
   conexao.close()

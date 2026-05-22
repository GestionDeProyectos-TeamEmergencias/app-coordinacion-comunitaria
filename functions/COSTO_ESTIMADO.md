## Costo Estimado Documentado

Modelo utilizado: `gemini-2.5-flash-lite`

- **Input tokens:** $0.075 / 1 millón
- **Output tokens:** $0.30 / 1 millón

**Cálculo por 100 reportes:**
Asumiendo ~100 tokens de input (prompt + reporte) y ~50 tokens de output (JSON con categoría y prioridad) por cada ejecución.

- 100 reportes x 100 tokens de input = 10.000 tokens de input = $0.00075
- 100 reportes x 50 tokens de output = 5.000 tokens de output = $0.0015

**Costo Total Estimado por cada 100 reportes procesados:** ~$0.00225

*(Lo cual cumple sobradamente con el criterio de aceptación `< $0.01 cada 100 reportes`).*
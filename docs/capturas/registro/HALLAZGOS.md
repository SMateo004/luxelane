# Capturas del registro de chóferes (Parte B, B4)

Estados nuevos de la app del chófer en es, en y pt a 390, 768 y 1280 px, y a
390 px con el texto al 200 % (font-size raíz del navegador); el panel, solo en
español (siempre sale en español). Contra los emuladores (demo-luxelane) con
datos y un documento FICTICIOS (`seed_registro.cjs`, `fixtures/documento_ficticio.jpg`).
Guion: `tools/experiencia/capturas_registro.cjs`. Resultado de cada una en
`manifiesto.json`: **170 de 180**.

La app del chófer se compiló con `CAPTURE_WEB_UPLOADS` (solo con `USE_EMULATORS`)
para ver en la web los pasos de la cámara; la foto se elige con el selector de
archivos del navegador. En producción la web no sube documentos (el aviso «se
suben desde la app de tu teléfono» lo cubre registration_pages_test.dart).

| Estado | Qué se ve |
|---|---|
| r01-previa | Pantalla previa: la cuenta pasa a ser de chófer, sin vuelta atrás; con reservas, otro correo |
| r02-previa-confirmar | Confirmación antes de llamar a startDriverApplication |
| r03-datos | Paso 1: datos personales (vacío) |
| r04-vehiculo | Paso 2: vehículo con los datos guardados |
| r05-documentos | Paso 3 con «necesita cambios»: estados, motivo de rechazo, nota y «Volver a subir» |
| r06-foto-en-vivo | Guía de la foto en vivo: solo cámara frontal, sin galería |
| r07-revision-foto | Revisión de la foto antes de enviar (repetir o usar) con la fecha de vencimiento |
| r08-falta-vencimiento | «Usar esta foto» sin fecha: se pide la fecha |
| r09-resumen | Resumen y envío con lo que falta |
| r10-segundo-factor | Con mfaEnforced: paso de verificación en dos pasos (5 pasos) |
| r11-en-revision | Enviada: «Solicitud en revisión», sin plazos |
| r12-no-aprobada | Rechazada y cerrada |
| r13-sin-requisitos | Sin config/ops.driverRequirements: aviso y sin documentos |
| p01-bandeja | Panel: bandeja por estado |
| p02-detalle | Panel: datos, vehículo y documentos |
| p03-visor | Panel: visor con el aviso de los 5 minutos (en el emulador la «URL firmada» es el archivo en data:, ver callables.cjs) |
| p04-rechazo | Panel: rechazo con motivos de lista cerrada |
| p05-decision | Panel: decisión final con motivo |
| p06-bitacora | Panel: bitácora de accesos |
| p07-vencimientos | Panel: vencimientos próximos y «Autorizar en línea» |
| p08-sin-requisitos | Panel: «Requisitos sin configurar» |

## No capturadas

- es/r04-vehiculo a 390 px, texto al 200 %: locator.click: Timeout 30000ms exceeded.
- pt/r04-vehiculo a 390 px, texto al 200 %: locator.click: Timeout 30000ms exceeded.
- es/r07-revision-foto a 390 px, texto al 200 %: locator.click: Timeout 30000ms exceeded.
- pt/r07-revision-foto a 390 px, texto al 200 %: locator.click: Timeout 30000ms exceeded.
- es/r08-falta-vencimiento a 390 px, texto al 200 %: locator.click: Timeout 30000ms exceeded.
- pt/r08-falta-vencimiento a 390 px, texto al 200 %: locator.click: Timeout 30000ms exceeded.
- pt/r09-resumen a 390 px, texto al 200 %: locator.click: Timeout 30000ms exceeded.
- es/r10-segundo-factor a 390 px, texto al 200 %: locator.click: Timeout 30000ms exceeded.
- pt/r10-segundo-factor a 390 px, texto al 200 %: locator.click: Timeout 30000ms exceeded.
- es/r09-resumen a 390 px, texto al 200 %: locator.click: Timeout 30000ms exceeded.

Las diez son estados a los que se llega desplazando (o tocando un botón que
queda abajo) con el texto al 200 % en español y portugués: Flutter web no crea
la semántica de lo que está lejos de la vista y la rueda no desplazó el lienzo
en el guion. No es un fallo de la app que se haya visto; el texto al 200 % sin
desbordes en esos estados, a 390, 768 y 1280 px y en los tres idiomas, lo
comprueba registration_pages_test.dart. NO VERIFICADO en un navegador real.

## Lector de pantalla (árbol de semántica a 390 px)

- Botones sin etiqueta: 0 en los 47 estados auditados.
- Objetivos de menos de 48 px que salieron (todos en el borde de la ventana: la
  semántica recorta lo que queda medio fuera [Probable]; el test
  `androidTapTargetGuideline` pasa):
  - es/r05-documentos: Volver a subir 141x36
  - en/r05-documentos: Upload again 138x16
  - pt/r05-documentos: Enviar novamente 168x16
  - es/p01-bandeja: Aprobada Aprobada 25x48
  - es/r04-vehiculo: Guardar y continuar Guardar y continuar 342x15
  - en/r09-resumen: Back Back 342x44
  - pt/r09-resumen: Voltar Voltar 342x44

## Hallazgos

0. Las capturas muestran el nombre anterior del certificado («Certificado
   penal»); después volvió a llamarse «Certificado de antecedentes» (en:
   «Criminal record certificate», pt: «Certidão de antecedentes criminais»).

1. La nota libre del admin al rechazar sale tal como la escribió (en español),
   también con la app en inglés o portugués; el motivo de la lista sí se traduce.
2. Con el texto al 200 %, el icono de los botones no crece con el texto.
3. El nombre accesible de los botones principales sale repetido («Continuar
   Continuar»): ya pasaba en otros botones de la app (LuxButton); no se corrigió aquí.
4. En el panel, tras desplazar con la rueda, el guion abrió otro documento que
   el pedido: la semántica de Flutter web va con retraso respecto al lienzo
   [Probable]; el test del panel comprueba que se abre el documento pedido.
5. La guía de encuadre se ve antes de abrir la cámara, no dentro de ella (no
   hay cámara propia). En el teléfono la cámara del sistema se abre a pantalla
   completa: NO VERIFICADO en dispositivo real.

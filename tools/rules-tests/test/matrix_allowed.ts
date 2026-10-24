// Por qué está permitida cada celda S de la matriz (matrix.ts), para la
// revisión humana de docs/MATRIZ_ACCESO_PERMITIDOS.md. `warn` marca con ⚠
// las celdas que parecen más amplias de lo necesario. Un test exige una
// razón para cada celda permitida y ninguna para las denegadas.
import { OPS, Op, Role, ROLE_LABELS, ROLES, SPECS, allowed } from './matrix';

export interface Why { why: string; warn?: string }
type Cells = Partial<Record<Role, Partial<Record<Op, Why>>>>;

const D10 = 'el panel aún escribe esto directo desde el cliente (D10); pasa a callables con auditoría en el servidor en la Parte B o después.';

export const ALLOWED: Record<string, Cells> = {
  'users/{uid}': {
    ana: {
      leer: { why: 'el usuario lee su propio perfil' },
      actualizar: { why: 'el usuario edita su nombre, teléfono, foto, preferencias y tokens de push (no rol, isActive, stripeCustomerId ni isVerified)' },
    },
    bloq: {
      leer: { why: 'una cuenta bloqueada sigue leyendo su perfil (la app lo usa para detectar el bloqueo y cerrar sesión)' },
      actualizar: {
        why: 'la regla del dueño no mira isActive',
        warn: 'un bloqueado aún puede cambiar su nombre, teléfono o tokens de push. Sin efecto en viajes, pero podría exigirse isActive (salvo quitar tokens al cerrar sesión).',
      },
    },
    admin: {
      leer: { why: 'el panel muestra los usuarios' },
      listar: { why: 'el panel lista los usuarios' },
      actualizar: { why: 'el admin cambia rol e isActive desde el panel', warn: D10 },
    },
  },
  'users/{uid}/notifications': {
    ana: {
      leer: { why: 'el usuario lee sus avisos' },
      listar: { why: 'la bandeja lista sus avisos' },
      actualizar: { why: 'marca sus avisos como leídos (solo isRead)' },
      borrar: { why: 'borra sus avisos' },
    },
    bloq: {
      leer: { why: 'como cualquier dueño: lee sus avisos' },
      listar: { why: 'como cualquier dueño: lista sus avisos' },
      actualizar: { why: 'como cualquier dueño: marca leídos' },
      borrar: { why: 'como cualquier dueño: borra los suyos' },
    },
    admin: {
      leer: { why: 'soporte' },
      listar: { why: 'soporte' },
      actualizar: { why: 'soporte' },
      borrar: { why: 'soporte' },
    },
  },
  'driverProfiles/{uid}': {
    asig: {
      leer: { why: 'el chófer lee su perfil' },
      crear: { why: 'alta del chófer: crea su propio perfil sin verificación ni valoración' },
      actualizar: { why: 'cambia disponibilidad y ubicación; licencia y vehículo, solo antes de verificar (H4)' },
    },
    libre: { crear: { why: 'alta del chófer: crea su propio perfil' } },
    nover: { crear: { why: 'alta del chófer: crea su propio perfil' } },
    bloq: {
      leer: { why: 'el chófer lee su perfil' },
      actualizar: { why: 'con la cuenta bloqueada solo puede dejar de estar disponible (isAvailable y online en false), H10' },
    },
    admin: {
      leer: { why: 'el panel muestra los chóferes' },
      listar: { why: 'el panel lista los chóferes' },
      actualizar: { why: 'verificar documentos y cambiar licencia a petición del chófer (con registro en admin_logs)', warn: D10 },
    },
  },
  'bookings/{id}': {
    ana: {
      leer: { why: 'el pasajero dueño lee su reserva' },
      listar: { why: 'el pasajero lista sus reservas' },
      actualizar: { why: 'cancela su reserva antes de que empiece el viaje (o la valora al terminar)' },
    },
    asig: { leer: { why: 'el chófer asignado y activo lee la reserva que atiende' } },
    admin: {
      leer: { why: 'operación' },
      listar: { why: 'operación' },
      actualizar: { why: 'cancelar, asignar, ajustar precio desde el panel (no verificar ni completar fuera de in_progress)', warn: D10 },
    },
  },
  'bookings/{id}/tracking': {
    ana: {
      leer: { why: 'el pasajero ve dónde está su chófer mientras va, espera o lo lleva' },
      listar: { why: 'igual que leer' },
    },
    asig: {
      leer: { why: 'el chófer asignado ve su propia ubicación publicada' },
      listar: { why: 'igual que leer' },
      crear: { why: 'publica su ubicación (solo lat, lng y hora del servidor) mientras el viaje está vivo' },
      actualizar: { why: 'actualiza su ubicación en las mismas condiciones' },
    },
    admin: { leer: { why: 'seguimiento desde el panel' }, listar: { why: 'seguimiento desde el panel' } },
  },
  'bookings/{id}/driverContact': {
    ana: {
      leer: { why: 'el pasajero llama a su chófer mientras el viaje está vivo' },
      listar: { why: 'igual que leer' },
    },
    asig: { leer: { why: 'el chófer ve su propio teléfono' }, listar: { why: 'igual que leer' } },
    admin: { leer: { why: 'soporte' }, listar: { why: 'soporte' } },
  },
  'bookings/{id}/events': {
    ana: { leer: { why: 'el pasajero ve el historial de su viaje' }, listar: { why: 'igual que leer' } },
    asig: { leer: { why: 'el chófer asignado ve el historial del viaje' }, listar: { why: 'igual que leer' } },
    admin: { leer: { why: 'auditoría' }, listar: { why: 'auditoría' } },
  },
  'bookings/{id}/eventLocations': {
    admin: { leer: { why: 'ubicación del chófer en cada paso, para reclamos' }, listar: { why: 'igual que leer' } },
  },
  'bookings/{id}/eventDetails': {
    admin: { leer: { why: 'motivo de una verificación forzada y llegada lejos del punto' }, listar: { why: 'igual que leer' } },
  },
  'bookings/{id}/adminOnly': {
    admin: { leer: { why: 'estado de incidentes de la reserva' }, listar: { why: 'igual que leer' } },
  },
  'incidents/{id}': {
    ana: { leer: { why: 'quien pidió ayuda ve el estado de su aviso' }, listar: { why: 'igual que leer' } },
    bloq: { leer: { why: 'un bloqueado también ve el aviso que disparó' }, listar: { why: 'igual que leer' } },
    admin: { leer: { why: 'central atiende el aviso' }, listar: { why: 'franja de incidentes del panel' } },
  },
  'incidents/{id}/locations': {
    ana: {
      leer: { why: 'quien pidió ayuda ve las ubicaciones que compartió' },
      listar: { why: 'igual que leer' },
      crear: { why: 'publica su ubicación mientras el aviso está abierto (una por tramo de 10 s)' },
    },
    bloq: {
      leer: { why: 'igual que el pasajero' },
      listar: { why: 'igual que el pasajero' },
      crear: { why: 'pedir ayuda no depende de la cuenta: un bloqueado en un viaje también puede' },
    },
    admin: { leer: { why: 'central sigue a quien pidió ayuda' }, listar: { why: 'igual que leer' } },
  },
  'incidents/{id}/events': {
    admin: { leer: { why: 'registro del incidente' }, listar: { why: 'igual que leer' } },
  },
  'openRequests/{id}': {
    asig: { leer: { why: 'un chófer verificado y activo ve solicitudes sin datos personales' }, listar: { why: 'igual que leer' } },
    libre: { leer: { why: 'un chófer verificado y activo ve solicitudes sin datos personales' }, listar: { why: 'igual que leer' } },
    admin: { leer: { why: 'operación' }, listar: { why: 'operación' } },
  },
  'rides/{id}': {
    admin: { leer: { why: 'consultar los documentos heredados que queden' }, listar: { why: 'igual que leer' } },
  },
  'payments/{id}': {
    ana: { leer: { why: 'el pasajero ve sus pagos' }, listar: { why: 'historial de pagos' } },
    admin: {
      leer: { why: 'finanzas' },
      listar: { why: 'finanzas' },
      crear: { why: 'registrar un cobro manual (efectivo, QR)', warn: D10 },
      actualizar: { why: 'corregir un cobro manual', warn: D10 },
    },
  },
  'vehicles/{id}': {
    asig: {
      leer: { why: 'el chófer ve su vehículo' },
      listar: { why: 'su vehículo por consulta' },
      crear: {
        why: 'registra un vehículo propio, inactivo',
        warn: 'un chófer ya verificado puede registrar más vehículos inactivos (solo el admin los activa). Sin efecto hasta que se activen.',
      },
      actualizar: { why: 'cambia color y foto' },
    },
    libre: { crear: { why: 'registra su vehículo, inactivo' } },
    nover: { crear: { why: 'alta: registra su vehículo, inactivo' } },
    bloq: {
      leer: { why: 've su vehículo' },
      listar: { why: 'su vehículo por consulta' },
      actualizar: { why: 'la regla de color y foto no mira isActive', warn: 'un bloqueado aún cambia color o foto. Sin efecto en viajes.' },
    },
    admin: {
      leer: { why: 'flota' },
      listar: { why: 'flota' },
      actualizar: { why: 'activar, desactivar y corregir datos a petición del chófer', warn: D10 },
    },
  },
  'pricingRules/{id}': {
    ...Object.fromEntries((['anon', 'ana', 'beto', 'asig', 'libre', 'nover', 'bloq'] as Role[]).map((r) => [r, {
      leer: { why: 'tarifas públicas: la web las muestra sin sesión' },
      listar: { why: 'tarifas públicas: la web las lista sin sesión' },
    }])),
    admin: {
      leer: { why: 'editar tarifas' },
      listar: { why: 'editar tarifas' },
      crear: { why: 'nueva tarifa con importes válidos' },
      actualizar: { why: 'cambiar una tarifa con importes válidos' },
      borrar: { why: 'quitar una tarifa (la clase deja de reservarse)' },
    },
  },
  'config/global': {
    ...Object.fromEntries((['anon', 'ana', 'beto', 'asig', 'libre', 'nover', 'bloq'] as Role[]).map((r) => [r, {
      leer: {
        why: 'estado operativo que la app lee antes de iniciar sesión (mantenimiento, versión mínima, teléfonos de central)',
        ...(r === 'anon' ? { warn: 'todo lo que se guarde en config/global es público, también sin sesión: no guardar ahí nada interno (hoy también lleva los tiempos de escalada del SOS y la retención).' } : {}),
      },
    }])),
    admin: {
      leer: { why: 'ajustes del panel' },
      listar: { why: 'ajustes del panel' },
      crear: { why: 'crear un documento de configuración' },
      actualizar: { why: 'cambiar ajustes', warn: D10 },
    },
  },
  'config/finance': {
    admin: {
      leer: { why: 'comisión de la plataforma' },
      listar: { why: 'ajustes del panel' },
      crear: { why: 'crear un documento de configuración (comisión entre 0 y 100)' },
      actualizar: { why: 'cambiar la comisión (entre 0 y 100)', warn: D10 },
    },
  },
  'businessLeads/{id}': {
    admin: {
      leer: { why: 'atender solicitudes de empresas' },
      listar: { why: 'bandeja de empresas' },
      actualizar: { why: 'marcar como atendida (solo handled)' },
    },
  },
  'adminAlerts/{id}': {
    admin: { leer: { why: 'avisos del servidor' }, listar: { why: 'avisos del servidor' } },
  },
  'admin_logs/{id}': {
    admin: {
      leer: { why: 'auditoría' },
      listar: { why: 'auditoría' },
      crear: {
        why: 'el panel anexa su propia auditoría (adminId = quien escribe)',
        warn: 'una auditoría escrita por el cliente se puede omitir o falsear en el detalle; la definitiva debe escribirla el servidor (D10).',
      },
    },
  },
};

const OP_LABEL: Record<Op, string> = {
  leer: 'leer', listar: 'listar', crear: 'crear', actualizar: 'actualizar', borrar: 'borrar',
};

/** Celdas permitidas sin razón, o con razón pero denegadas. */
export function allowedProblems(): string[] {
  const out: string[] = [];
  for (const s of SPECS) {
    for (const r of ROLES) {
      for (const o of OPS) {
        const w = ALLOWED[s.name]?.[r]?.[o];
        if (allowed(s, r, o) && !w) out.push(`sin razón: ${s.name} · ${r} · ${o}`);
        if (!allowed(s, r, o) && w) out.push(`razón de una celda denegada: ${s.name} · ${r} · ${o}`);
      }
    }
  }
  return out;
}

/** docs/MATRIZ_ACCESO_PERMITIDOS.md, por colección y por rol. */
export function renderAllowed(): string {
  const lines: string[] = [];
  let total = 0;
  let warns = 0;
  for (const s of SPECS) {
    const roles = ROLES.filter((r) => OPS.some((o) => allowed(s, r, o)));
    lines.push(`## \`${s.name}\``, '');
    if (roles.length === 0) {
      lines.push('Ninguna celda permitida.', '');
      continue;
    }
    for (const r of roles) {
      lines.push(`**${ROLE_LABELS[r]}**`, '');
      for (const o of OPS.filter((op) => allowed(s, r, op))) {
        const w = ALLOWED[s.name][r]![o]!;
        total++;
        if (w.warn) warns++;
        lines.push(`- ${w.warn ? '⚠ ' : ''}${OP_LABEL[o]}: ${w.why}.${w.warn ? ` **${w.warn}**` : ''}`);
      }
      lines.push('');
    }
  }
  return [`${total} celdas permitidas, ${warns} con ⚠.`, '', ...lines].join('\n').trimEnd();
}

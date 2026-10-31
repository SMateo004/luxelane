// Por qué está permitida cada celda S de la matriz (matrix.ts), para la
// revisión humana de docs/MATRIZ_ACCESO_PERMITIDOS.md. `warn` marca con ⚠
// las celdas que parecen más amplias de lo necesario. Un test exige una
// razón para cada celda permitida y ninguna para las denegadas.
import { OPS, Op, Role, ROLE_LABELS, ROLES, SPECS, allowed } from './matrix';

export interface Why { why: string; warn?: string }
type Cells = Partial<Record<Role, Partial<Record<Op, Why>>>>;


export const ALLOWED: Record<string, Cells> = {
  'users/{uid}': {
    ana: {
      leer: { why: 'el usuario lee su propio perfil' },
      actualizar: { why: 'el usuario edita su nombre, teléfono, foto y tokens de push (no rol, isActive, stripeCustomerId, isVerified, preferencias ni idioma: esos, updatePreferences)' },
    },
    bloq: {
      leer: { why: 'una cuenta bloqueada sigue leyendo su perfil (la app lo usa para detectar el bloqueo y cerrar sesión)' },
    },
    admin: {
      leer: { why: 'el panel muestra los usuarios' },
      listar: { why: 'el panel lista los usuarios' },
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
    },
  },
  'bookings/{id}': {
    ana: {
      leer: { why: 'el pasajero dueño lee su reserva' },
      listar: { why: 'el pasajero lista sus reservas' },
    },
    asig: { leer: { why: 'el chófer asignado y activo lee la reserva que atiende' } },
    admin: {
      leer: { why: 'operación' },
      listar: { why: 'operación' },
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
  'bookings/{id}/driverView': {
    ana: {
      leer: { why: 'el pasajero dueño ve las preferencias que dejó para ese viaje' },
      listar: { why: 'igual que leer' },
    },
    asig: {
      leer: { why: 'el chófer asignado y activo ve las preferencias del viaje que atiende, solo entre confirmed e in_progress' },
      listar: { why: 'igual que leer' },
    },
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
    ana: { leer: { why: 'el pasajero ve sus pagos y los asientos de su reserva (cobro, reembolso, retención)' }, listar: { why: 'historial de pagos' } },
    admin: {
      leer: { why: 'finanzas' },
      listar: { why: 'finanzas' },
    },
  },
  'bookings/{id}/payment': {
    ana: {
      leer: { why: 'el pasajero ve el estado del pago de su reserva (importe, referencia, plazo)' },
      listar: { why: 'el mismo documento por consulta (riderId)' },
    },
    admin: {
      leer: { why: 'bandejas de pagos, confirmación y reembolsos' },
      listar: { why: 'bandejas de pagos' },
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
    },
    admin: {
      leer: { why: 'flota' },
      listar: { why: 'flota' },
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
    },
  },
  'config/global': {
    ...Object.fromEntries((['anon', 'ana', 'beto', 'asig', 'libre', 'nover', 'bloq'] as Role[]).map((r) => [r, {
      leer: {
        why: 'estado operativo que la app lee antes de iniciar sesión (mantenimiento, versión mínima, teléfonos de central)',
        ...(r === 'anon' ? { warn: 'todo lo que se guarde en config/global es público, también sin sesión: no guardar ahí nada interno (los tiempos del SOS, la retención y el radio de llegada pasaron a config/ops; el segundo factor irá en config/security).' } : {}),
      },
    }])),
    admin: {
      leer: { why: 'ajustes del panel' },
    },
  },
  'config/finance': {
    admin: {
      leer: { why: 'comisión de la plataforma' },
    },
  },
  'config/ops': {
    admin: { leer: { why: 'ver los tiempos del SOS, la retención, el radio de llegada y el límite de ajuste (se editan con adminUpdateConfig o en la consola)' } },
  },
  'businessLeads/{id}': {
    admin: {
      leer: { why: 'atender solicitudes de empresas' },
      listar: { why: 'bandeja de empresas' },
    },
  },
  'adminAlerts/{id}': {
    admin: { leer: { why: 'avisos del servidor' }, listar: { why: 'avisos del servidor' } },
  },
  'driverDevices/{uid}/devices/{id}': {
    admin: { leer: { why: 'revisar dispositivos nuevos' }, listar: { why: 'dispositivos del chófer' } },
  },
  'admin_logs/{id}': {
    admin: {
      leer: { why: 'auditoría' },
      listar: { why: 'auditoría' },
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

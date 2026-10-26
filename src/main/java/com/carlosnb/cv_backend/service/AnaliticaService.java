package com.carlosnb.cv_backend.service;

import com.carlosnb.cv_backend.entity.EventoCv;
import com.carlosnb.cv_backend.entity.SesionVisita;
import com.carlosnb.cv_backend.repository.EventoCvRepository;
import com.carlosnb.cv_backend.repository.SesionVisitaRepository;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.OffsetDateTime;

@Service
@RequiredArgsConstructor
public class AnaliticaService {

    private final SesionVisitaRepository sesionVisitaRepository;
    private final EventoCvRepository eventoCvRepository;

    // Usamos @Async para que el guardado no bloquee la respuesta del CV al usuario
    @Async
    @Transactional
    public void registrarVisitaYCvVisto(Integer cvId, HttpServletRequest request) {
        
        // 1. Extraer información del request
        String userAgent = request.getHeader("User-Agent");
        String ip = request.getRemoteAddr(); // Nota: En producción detrás de un proxy (ej. Nginx/Cloudflare) usa X-Forwarded-For
        
        // 2. Detectar Bot (Lógica simple basada en User-Agent)
        boolean esBot = userAgent != null && userAgent.toLowerCase().matches(".*(bot|crawler|spider|googlebot|bingbot).*");
        if (esBot) return; // Si es bot, no registramos nada

        // 3. Detectar Dispositivo y Navegador (Lógica básica)
        String dispositivo = "OTRO";
        String navegador = "Desconocido";
        if (userAgent != null) {
            if (userAgent.contains("Mobile")) dispositivo = "MOVIL";
            else if (userAgent.contains("Tablet")) dispositivo = "TABLET";
            else dispositivo = "ESCRITORIO";

            if (userAgent.contains("Chrome")) navegador = "Chrome";
            else if (userAgent.contains("Firefox")) navegador = "Firefox";
            else if (userAgent.contains("Safari")) navegador = "Safari";
            else if (userAgent.contains("Edge")) navegador = "Edge";
        }

        // 4. Crear y guardar la Sesión
        SesionVisita sesion = new SesionVisita();
        sesion.setCvId(cvId);
        sesion.setVisitanteHash(generarHash(ip + userAgent)); // Hash para privacidad
        sesion.setDispositivo(dispositivo);
        sesion.setNavegador(navegador);
        sesion.setEsBot(false);
        sesion = sesionVisitaRepository.save(sesion);

        // 5. Crear y guardar el Evento (VISTA_CV = tipo_evento_id 1, según tu SQL)
        EventoCv evento = new EventoCv();
        evento.setSesionVisitaId(sesion.getId());
        evento.setTipoEventoId((short) 1); // 1 = VISTA_CV
        evento.setOcurrioEn(OffsetDateTime.now());
        eventoCvRepository.save(evento);
    }

    // Método auxiliar para generar SHA-256
    private String generarHash(String texto) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(texto.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("Error generando hash", e);
        }
    }
}
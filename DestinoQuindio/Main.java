import java.sql.Connection;

import src.controller.*;
import src.dao.ConexionBD;
import src.model.Usuario;

public class Main {
    public static void main(String[] args) {
        // Verificar conexión a la base de datos
        try (Connection conn = ConexionBD.getConnection()) {
            if (conn != null) {
                System.out.println("✅ Conexión exitosa a la base de datos.");
            } else {
                System.out.println("❌ No se pudo establecer conexión a la base de datos.");
            }
        } catch (Exception e) {
            System.err.println("❌ Error al conectar a la base de datos: " + e.getMessage());
        }

       Usuario usuario = new Usuario();
        usuario.setNombre("Juan Pérez");
       

        // Iniciar el formulario de login
        //new LoginForm();
        //new MenuAdmin(usuario);
        //new MenuCliente(usuario);
        new MenuConductor(usuario);
    }

}

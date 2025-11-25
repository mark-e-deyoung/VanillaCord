package vanillacord.compat;

import org.junit.jupiter.api.Assumptions;
import org.junit.jupiter.api.Test;

import java.lang.reflect.Method;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.junit.jupiter.api.Assertions.assertNotNull;

class MinecraftCompatibilityTest {

    @Test
    void serverJarContainsExpectedEntryPoints() throws Exception {
        String jarProp = System.getProperty("minecraft.serverJar", "").trim();
        Assumptions.assumeTrue(!jarProp.isEmpty(), "minecraft.serverJar not provided; skipping compatibility probe");

        Path jar = Path.of(jarProp);
        Assumptions.assumeTrue(Files.isRegularFile(jar), "server jar not found: " + jar);

        try (URLClassLoader cl = new URLClassLoader(new URL[]{jar.toUri().toURL()}, null)) {
            Class<?> sharedConstants = Class.forName("net.minecraft.SharedConstants", true, cl);
            Method getGameVersion = sharedConstants.getMethod("getGameVersion");
            Object gameVersion = getGameVersion.invoke(null);
            Method getName = gameVersion.getClass().getMethod("getName");
            String name = (String) getName.invoke(gameVersion);
            assertNotNull(name, "SharedConstants#getGameVersion().getName() returned null");

            Class.forName("net.minecraft.server.MinecraftServer", false, cl);
            Class.forName("io.netty.buffer.ByteBuf", false, cl);
            Class.forName("com.mojang.authlib.GameProfile", false, cl);
        }
    }
}

package vanillacord;

import org.junit.jupiter.api.Test;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

class PatcherManifestTest {

    @Test
    void manifestFiltersAndAnnotates() throws Exception {
        String manifest = ""
                + "Manifest-Version: 1.0\n"
                + "Main-Class: example.Main\n"
                + "Ignored: value\n"
                + "Bundler-Format: bundle\n"
                + "Multi-Release: true\n";

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Patcher.manifest(new ByteArrayInputStream(manifest.getBytes(StandardCharsets.UTF_8)), out);

        String result = out.toString(StandardCharsets.UTF_8);
        assertTrue(result.contains("Manifest-Version: 1.0"));
        assertTrue(result.contains("Main-Class: example.Main"));
        assertTrue(result.contains("Bundler-Format: bundle"));
        assertTrue(result.contains("Multi-Release: true"));
        assertTrue(result.contains("Built-By: " + Patcher.brand));
        assertFalse(result.contains("Ignored: value"));
    }
}

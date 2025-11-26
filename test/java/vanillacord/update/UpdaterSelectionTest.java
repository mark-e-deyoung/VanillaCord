package vanillacord.update;

import org.junit.jupiter.api.Test;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;
import vanillacord.packaging.Package;

import java.lang.reflect.Field;
import java.nio.file.Path;
import java.util.function.Function;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

import static org.junit.jupiter.api.Assertions.assertTrue;

class UpdaterSelectionTest {

    private static final class StubPackage extends Package {
        @Override
        public ZipInputStream read(Path path) {
            throw new UnsupportedOperationException("stub");
        }

        @Override
        public ZipOutputStream write(Path path) {
            throw new UnsupportedOperationException("stub");
        }
    }

    @Test
    @SuppressWarnings("unchecked")
    void prefersAuthLibPropertyWhenPropertyIsRecord() throws Exception {
        StubPackage file = new StubPackage();
        Updater updater = new Updater(getClass().getClassLoader(), file);

        Field updates = Updater.class.getDeclaredField("updates");
        updates.setAccessible(true);
        Function<MethodVisitor, MethodVisitor> factory = (Function<MethodVisitor, MethodVisitor>) updates.get(updater);

        MethodVisitor result = factory.apply(new MethodVisitor(Opcodes.ASM9) {});
        assertTrue(result instanceof AuthLibProperty, "Expected authlib helper when Property is a record");
    }
}

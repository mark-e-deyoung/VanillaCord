package vanillacord.data;

import org.junit.jupiter.api.Test;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;
import vanillacord.packaging.Package;

import java.nio.file.Path;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

import static org.junit.jupiter.api.Assertions.assertNotNull;

class SourceScannerTest {

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
    void identifiesHookPointsFromLiterals() {
        StubPackage file = new StubPackage();
        byte[] bytes = buildProbeClass();

        new ClassReader(bytes).accept(new SourceScanner(file), ClassReader.SKIP_FRAMES | ClassReader.SKIP_DEBUG);

        assertNotNull(file.sources.startup, "startup not detected");
        assertNotNull(file.sources.login, "login not detected");
        assertNotNull(file.sources.handshake, "handshake not detected");
        assertNotNull(file.sources.send, "send not detected");
        assertNotNull(file.sources.receive, "receive not detected");
    }

    private static byte[] buildProbeClass() {
        ClassWriter cw = new ClassWriter(0);
        cw.visit(Opcodes.V21, Opcodes.ACC_PUBLIC, "vanillacord/test/Probe", null, "java/lang/Object", null);

        // Non-static int field enables the login extension detection path.
        cw.visitField(Opcodes.ACC_PUBLIC, "tid", "I", null, null).visitEnd();

        addStringLdcMethod(cw, "startup", "Server console handler");
        addStringLdcMethod(cw, "login", "Unexpected hello");
        addStringLdcMethod(cw, "handshake", "outdated client! please use");
        addStringLdcMethod(cw, "send", "payload too large");
        addStringLdcMethod(cw, "receive", "payload too large");

        cw.visitEnd();
        return cw.toByteArray();
    }

    private static void addStringLdcMethod(ClassWriter cw, String name, String literal) {
        MethodVisitor mv = cw.visitMethod(Opcodes.ACC_PUBLIC, name, "()V", null, null);
        mv.visitCode();
        mv.visitLdcInsn(literal);
        mv.visitInsn(Opcodes.POP);
        mv.visitInsn(Opcodes.RETURN);
        mv.visitMaxs(1, 1);
        mv.visitEnd();
    }
}

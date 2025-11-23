package vanillacord.data;

import bridge.asm.HierarchyScanner;
import org.objectweb.asm.FieldVisitor;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;
import vanillacord.packaging.Package;

import java.util.Locale;

public class SourceScanner extends HierarchyScanner {
    private final Package file;
    private ClassData data;
    private boolean hasTID;

    public SourceScanner(Package file) {
        super(Opcodes.ASM9, file.types);
        this.file = file;
    }

    @Override
    public void visit(int version, int access, String name, String signature, String extended, String[] implemented) {
        super.visit(version, access, name, signature, extended, implemented);
        super.data = this.data = new ClassData(file.types, compile(), signature);
    }

    @Override
    public FieldVisitor visitField(int access, String name, String descriptor, String signature, Object value) {
        this.data.fields.put(descriptor + name, new FieldData(this.data, access, name, descriptor, signature, value));
        if ((access & Opcodes.ACC_STATIC) == 0) {
            if (!hasTID && descriptor.equals("I")) hasTID = true;
        }
        return super.visitField(access, name, descriptor, signature, value);
    }

    @Override
    public MethodVisitor visitMethod(int access, String name, String descriptor, String signature, String[] exceptions) {
        final MethodData data;
        this.data.methods.put(name + descriptor, data = new MethodData(this.data, access, name, descriptor, signature, exceptions));
        return new MethodVisitor(Opcodes.ASM9, super.visitMethod(access, name, descriptor, signature, exceptions)) {

            @Override
            public void visitLdcInsn(Object value) {
                if (value instanceof String) {
                    final String text = (String) value;
                    if ("Server console handler".equals(text)) {
                        System.out.print("Found the dedicated server: ");
                        System.out.println(SourceScanner.super.name);
                        file.sources.startup = data;
                    } else if (isLoginHello(text)) {
                        System.out.print("Found the login listener: ");
                        System.out.println(SourceScanner.super.name);
                        file.sources.login = data;
                    } else if (hasTID && isPayloadTooLarge(text)) {
                        System.out.print("Found a login extension packet: ");
                        System.out.println(SourceScanner.super.name);
                        if (file.sources.send == null) {
                            file.sources.send = data;
                        } else {
                            file.sources.receive = data;
                        }
                    } else if (isHandshakeDisconnect(text)) {
                        System.out.print("Found the handshake listener: ");
                        System.out.println(SourceScanner.super.name);
                        file.sources.handshake = data;
                    }
                }
                super.visitLdcInsn(value);
            }
        };
    }

    private static boolean isLoginHello(String text) {
        String lower = text.toLowerCase(Locale.ROOT);
        return lower.contains("unexpected hello")
                || lower.contains("unexpected login")
                || lower.contains("hello packet")
                || lower.contains("received hello twice");
    }

    private static boolean isPayloadTooLarge(String text) {
        String lower = text.toLowerCase(Locale.ROOT);
        return lower.contains("payload may not be larger")
                || lower.contains("payload too large")
                || text.contains("1048576");
    }

    private static boolean isHandshakeDisconnect(String text) {
        String lower = text.toLowerCase(Locale.ROOT);
        return lower.contains("multiplayer.disconnect.incompatible")
                || lower.contains("multiplayer.disconnect.outdated_server")
                || lower.contains("multiplayer.disconnect.outdated_client")
                || lower.contains("multiplayer.disconnect.incompatible.version")
                || lower.contains("outdated client! please use")
                || lower.contains("server is out of date");
    }
}

package vanillacord.update;

import bridge.asm.HierarchicalWriter;
import org.objectweb.asm.*;
import vanillacord.Patcher;
import vanillacord.data.ClassData;
import vanillacord.packaging.Package;

import java.io.IOException;
import java.util.function.Function;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

public class Updater {
    private final Function<MethodVisitor, MethodVisitor> updates;
    private final ClassLoader source;
    private final Package file;

    public Updater(ClassLoader source, Package file) {
        this.file = file;
        this.source = source;

        if (isRecord("com/mojang/authlib/properties/Property")) {
            this.updates = AuthLibProperty::new;
        } else { // 1.20 > version
            final Object key;
            if (!((key = file.types.loadClass("io/netty/util/AttributeKey").data()) instanceof ClassData)
                    || ((ClassData) key).methods.containsKey("valueOf(Ljava/lang/String;)Lio/netty/util/AttributeKey;")) {
                this.updates = AttributeKey::new;
            } else { // 1.12 > version
                this.updates = null;
            }
        }
    }

    public void update(String file, ZipOutputStream zos, byte[] buffer) throws IOException {
        zos.putNextEntry(new ZipEntry(file));
        if (updates == null) {
            Patcher.copy(source.getResourceAsStream(file), zos, buffer);
        } else {
            ClassReader reader = new ClassReader(source.getResourceAsStream(file));
            ClassWriter writer = new HierarchicalWriter(this.file.types, ClassWriter.COMPUTE_MAXS | ClassWriter.COMPUTE_FRAMES);
            reader.accept(new ClassVisitor(Opcodes.ASM9, writer) {
                @Override
                public MethodVisitor visitMethod(int access, String name, String descriptor, String signature, String[] exceptions) {
                    return updates.apply(super.visitMethod(access, name, descriptor, signature, exceptions));
                }
            }, 0);
            zos.write(writer.toByteArray());
        }
    }

    private boolean isRecord(String internalName) {
        try {
            if (file.types.loadClass(internalName).extended(file.types.loadClass("java/lang/Record"))) {
                return true;
            }
        } catch (Throwable ignored) {
        }

        try {
            Class<?> type = Class.forName(internalName.replace('/', '.'), false, source);
            return Record.class.isAssignableFrom(type);
        } catch (ClassNotFoundException ignored) {
            return false;
        }
    }
}

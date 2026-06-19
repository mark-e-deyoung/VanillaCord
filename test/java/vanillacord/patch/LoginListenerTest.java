package vanillacord.patch;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.objectweb.asm.Opcodes.ACC_FINAL;
import static org.objectweb.asm.Opcodes.ACC_PRIVATE;
import static org.objectweb.asm.Opcodes.ACC_PROTECTED;
import static org.objectweb.asm.Opcodes.ACC_PUBLIC;
import static org.objectweb.asm.Opcodes.ACC_SYNTHETIC;

class LoginListenerTest {

    @Test
    void makesConnectionFieldPublicWithoutDroppingOtherFlags() {
        int access = LoginListener.makePublic(ACC_PRIVATE | ACC_FINAL | ACC_SYNTHETIC);

        assertTrue((access & ACC_PUBLIC) != 0);
        assertEquals(0, access & (ACC_PRIVATE | ACC_PROTECTED));
        assertTrue((access & ACC_FINAL) != 0);
        assertTrue((access & ACC_SYNTHETIC) != 0);
    }
}

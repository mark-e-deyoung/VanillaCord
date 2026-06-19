package vanillacord.server;

import com.mojang.authlib.GameProfile;
import com.mojang.authlib.properties.Property;
import com.mojang.authlib.properties.PropertyMap;
import com.google.common.collect.Multimap;

import java.lang.reflect.Constructor;
import java.util.UUID;

public abstract class ForwardingHelper {

    ForwardingHelper() {

    }

    public void parseHandshake(Object connection, Object handshake) {

    }

    public boolean initializeTransaction(Object connection, Object hello) {
        return false;
    }

    public boolean completeTransaction(Object connection, Object login, Object response) {
        return false;
    }

    public abstract GameProfile injectProfile(Object connection, String username);

    /**
     * Creates a GameProfile with the given properties pre-populated.
     * Works with both old authlib (mutable PropertyMap via getProperties().putAll)
     * and new authlib (record-based, requires 3-arg constructor via reflection).
     */
    @SuppressWarnings("unchecked")
    public static GameProfile createProfile(UUID id, String name, Multimap<String, Property> properties) {
        try {
            Constructor<PropertyMap> pmCtor = PropertyMap.class.getConstructor(Multimap.class);
            Constructor<GameProfile> gpCtor = GameProfile.class.getConstructor(
                    UUID.class, String.class, PropertyMap.class);
            return gpCtor.newInstance(id, name, pmCtor.newInstance(properties));
        } catch (ReflectiveOperationException e) {
            GameProfile profile = new GameProfile(id, name);
            profile.getProperties().putAll(properties);
            return profile;
        }
    }
}

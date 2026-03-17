# Maven Packaging Guide

Maven packaging is a core part of the Java build lifecycle, defining how a project is compiled, tested, and bundled for distribution. Here's a comprehensive overview.

## 1. Common Packaging Types

Maven supports several packaging types, defined in the `<packaging>` element of your `pom.xml`:

| Packaging Type | Description                    | Output File          |
|----------------|--------------------------------|----------------------|
| `jar`          | Java Archive (default)         | `.jar`               |
| `war`          | Web Application Archive        | `.war`               |
| `pom`          | Project Object Model (parent)  | `.pom`               |
| `ear`          | Enterprise Application Archive | `.ear`               |
| `rar`          | Resource Adapter Archive       | `.rar`               |

Example:
```xml
<packaging>jar</packaging>
```

## 2. Basic Packaging Commands

Use the following Maven commands to package your project:

```bash
# Compile and package
mvn package

# Skip tests during packaging
mvn package -DskipTests

# Clean and package
mvn clean package

# Install to local repository
mvn install

# Deploy to remote repository
mvn deploy
```

## 3. Configuring the JAR Plugin

Customize your JAR packaging using the `maven-jar-plugin`:

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-jar-plugin</artifactId>
            <version>3.3.0</version>
            <configuration>
                <archive>
                    <manifest>
                        <mainClass>com.example.Main</mainClass>
                    </manifest>
                </archive>
            </configuration>
        </plugin>
    </plugins>
</build>
```

## 4. Creating an Executable JAR (with Dependencies)

To bundle all dependencies into a single runnable JAR, use the `maven-assembly-plugin` or `maven-shade-plugin`.

### Using Assembly Plugin:
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-assembly-plugin</artifactId>
    <version>3.6.0</version>
    <configuration>
        <archive>
            <manifest>
                <mainClass>com.example.Main</mainClass>
            </manifest>
        </archive>
        <descriptorRefs>
            <descriptorRef>jar-with-dependencies</descriptorRef>
        </descriptorRefs>
    </configuration>
    <executions>
        <execution>
            <id>make-assembly</id>
            <phase>package</phase>
            <goals>
                <goal>single</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

### Using Shade Plugin (Recommended):
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-shade-plugin</artifactId>
    <version>3.5.0</version>
    <executions>
        <execution>
            <phase>package</phase>
            <goals>
                <goal>shade</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

## 5. WAR Packaging (for Web Applications)

For web apps, use `war` packaging and configure the `maven-war-plugin`:

```xml
<packaging>war</packaging>

<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-war-plugin</artifactId>
    <version>3.4.0</version>
    <configuration>
        <failOnMissingWebXml>false</failOnMissingWebXml>
    </configuration>
</plugin>
```

## 6. Build Profiles for Environment-Specific Packaging

Use Maven profiles to customize packaging for different environments:

```xml
<profiles>
    <profile>
        <id>dev</id>
        <properties>
            <environment>development</environment>
        </properties>
    </profile>
    <profile>
        <id>prod</id>
        <properties>
            <environment>production</environment>
        </properties>
    </profile>
</profiles>
```

Activate with:
```bash
mvn package -Pprod
```

## 7. Best Practices

- ✅ Use semantic versioning for your project
- ✅ Configure source and Javadoc JARs for publishing
- ✅ Use the Shade plugin for executable JARs
- ✅ Skip tests in CI/CD pipelines when appropriate
- ✅ Clean build artifacts before packaging
- ✅ Use profiles for environment-specific configurations

Example: Generate source and Javadoc JARs:
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-source-plugin</artifactId>
    <version>3.3.0</version>
    <executions>
        <execution>
            <id>attach-sources</id>
            <goals>
                <goal>jar-no-fork</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```

## 8. Output Locations

After packaging, artifacts are located at:

- **Compiled classes:** `target/classes/`
- **Packaged artifact:** `target/*.jar` or `target/*.war`
- **Test results:** `target/surefire-reports/`

---

By understanding and configuring Maven packaging properly, you ensure consistent, reproducible builds ready for deployment or distribution.
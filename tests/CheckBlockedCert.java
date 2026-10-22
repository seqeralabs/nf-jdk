import java.io.FileInputStream;
import java.security.cert.CertPathValidator;
import java.security.cert.CertPathValidatorException;
import java.security.cert.CertificateFactory;
import java.security.cert.PKIXParameters;
import java.security.cert.TrustAnchor;
import java.security.cert.X509Certificate;
import java.util.List;
import java.util.Set;

/**
 * Validates a CA certificate against an explicit trust anchor and exits with 0
 * only when the JDK rejects it as an untrusted (blocked) certificate.
 *
 * Usage: java CheckBlockedCert.java <cert.pem> <anchor.pem>
 *
 * The anchor is explicit because the image trust store may not contain the
 * issuing root, while blocked.certs applies to any trust store an application
 * configures.
 */
public class CheckBlockedCert {
    public static void main(String[] args) throws Exception {
        X509Certificate cert = load(args[0]);
        X509Certificate anchor = load(args[1]);
        PKIXParameters params = new PKIXParameters(Set.of(new TrustAnchor(anchor, null)));
        params.setRevocationEnabled(false);
        try {
            CertificateFactory cf = CertificateFactory.getInstance("X.509");
            CertPathValidator.getInstance("PKIX").validate(cf.generateCertPath(List.of(cert)), params);
            System.out.println("ACCEPTED: " + cert.getSubjectX500Principal());
            System.exit(1);
        } catch (CertPathValidatorException e) {
            System.out.println("REJECTED: " + e.getMessage());
            System.exit(e.getMessage().startsWith("Untrusted certificate") ? 0 : 2);
        }
    }

    private static X509Certificate load(String path) throws Exception {
        try (FileInputStream in = new FileInputStream(path)) {
            return (X509Certificate) CertificateFactory.getInstance("X.509").generateCertificate(in);
        }
    }
}

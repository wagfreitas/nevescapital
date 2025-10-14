import { auth } from './firebase';

type NextFunction = () => void;

export interface AuthenticatedRequest {
  headers: Record<string, string | string[] | undefined>;
  body?: any;
  user?: {
    uid: string;
    email: string;
  };
}

interface ResponseLike {
  status: (code: number) => ResponseLike;
  json: (body: Record<string, unknown>) => void;
}

export async function authenticate(req: AuthenticatedRequest, res: ResponseLike, next: NextFunction) {
  const authorization = req.headers.authorization;
  if (!authorization) {
    return res.status(401).json({ message: 'Token não informado' });
  }

  const headerValue = Array.isArray(authorization) ? authorization[0] : authorization;
  const parts = headerValue.split(' ');
  if (parts.length !== 2 || parts[0] !== 'Bearer') {
    return res.status(401).json({ message: 'Formato de autorização inválido' });
  }

  try {
    const decoded = await auth.verifyIdToken(parts[1]);
    req.user = {
      uid: decoded.uid,
      email: decoded.email ?? '',
    };
    next();
  } catch (error) {
    res.status(401).json({ message: 'Token inválido', details: String(error) });
  }
}

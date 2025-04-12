import {
  Catch,
  RpcExceptionFilter as RpcExceptionFilterType,
} from '@nestjs/common';
import { Observable, throwError } from 'rxjs';

@Catch()
export class RpcExceptionFilter implements RpcExceptionFilterType {
  catch(exception: any): Observable<any> {
    // Se for uma exceção HTTP do NestJS, convertemos para RpcException
    if (exception.status) {
      return throwError(() => ({
        status: exception.status,
        message: exception.message,
        error: exception.error || exception.message,
      }));
    }

    // Se já for uma RpcException, apenas propagamos
    if (exception.error) {
      return throwError(() => exception.error);
    }

    // Para outras exceções, retornamos um erro genérico
    return throwError(() => ({
      status: 500,
      message: 'Internal server error',
      error: exception.message,
    }));
  }
}
